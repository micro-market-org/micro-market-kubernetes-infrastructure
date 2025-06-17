resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "keycloak"
    }
  }
}

resource "random_password" "keycloak_admin_password" {
  length  = 16
  special = false
}

resource "random_password" "grafana_oidc_client_secret" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "keycloak_postgresql_secret" {
  metadata {
    name      = "keycloak-postgresql"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
  }

  data = {
    "POSTGRES_USER"     = "postgres"
    "POSTGRES_PASSWORD" = random_password.postgresql_password.result
    "POSTGRES_DB"       = var.project_name
    "POSTGRES_HOST"     = "postgresql.postgresql.svc.cluster.local"
    "POSTGRES_PORT"     = "5432"
  }
}

resource "kubernetes_secret_v1" "keycloak_admin_secret" {
  metadata {
    name      = "keycloak-admin"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
  }

  data = {
    "password" = random_password.keycloak_admin_password.result
  }
}

resource "helm_release" "keycloak" {
  name              = "keycloak"
  repository        = "https://charts.bitnami.com/bitnami"
  chart             = "keycloak"
  version           = "22.0.1"
  namespace         = kubernetes_namespace_v1.keycloak.metadata[0].name
  create_namespace  = false
  dependency_update = true
  timeout           = 300

  depends_on = [
    kubernetes_namespace_v1.keycloak,
    kubernetes_secret_v1.keycloak_postgresql_secret,
    kubernetes_secret_v1.keycloak_admin_secret,
    helm_release.postgresql
  ]

  values = [
    <<-EOT
    # Global parameters
    global:
      imageRegistry: ""
      imagePullSecrets: []
      defaultStorageClass: ""
      storageClass: ""
      security:
        allowInsecureImages: false
      compatibility:
        openshift:
          adaptSecurityContext: auto

    # Common parameters
    kubeVersion: ""
    nameOverride: ""
    fullnameOverride: ""
    namespaceOverride: ""
    commonLabels: {}
    enableServiceLinks: true
    commonAnnotations: {}
    dnsPolicy: ""
    dnsConfig: {}
    clusterDomain: cluster.local
    extraDeploy: []
    usePasswordFiles: true
    diagnosticMode:
      enabled: false
      command:
        - sleep
      args:
        - infinity

    replicaCount: 1

    # Production mode settings
    production: true

    # Admin realm
    adminRealm: "master"

    # Authentication
    auth:
      adminUser: admin
      existingSecret: keycloak-admin
      passwordSecretKey: password

    # Environment variables
    httpRelativePath: "/auth/"
    proxyHeaders: "xforwarded"
    proxy: ""
    extraEnvVars:
      - name: KEYCLOAK_ADMIN
        value: admin
      - name: KEYCLOAK_ADMIN_PASSWORD
        valueFrom:
          secretKeyRef:
            name: keycloak-admin
            key: password
      - name: KC_SPI_EVENTS_LISTENER_JBOSS_LOGGING_SUCCESS_LEVEL
        value: "debug"
      - name: KC_SPI_EVENTS_LISTENER_JBOSS_LOGGING_ERROR_LEVEL
        value: "debug"
      - name: KC_FEATURES
        value: "token-exchange,admin-fine-grained-authz"
      - name: KC_HOSTNAME
        value: "${local.current_domain}"
      - name: KC_DB
        value: "postgres"
      - name: KC_TRANSACTION_XA_ENABLED
        value: "true"
      - name: KC_HTTP_ENABLED
        value: "true"
      - name: KEYCLOAK_EXTRA_ARGS
        value: "--import-realm --spi-realm-import-strategy=OVERWRITE_EXISTING"
      - name: KC_HEALTH_ENABLED
        value: "true"
      - name: KC_METRICS_ENABLED
        value: "true"
      - name: KC_LOG_LEVEL
        value: "debug"

    # Database configuration
    externalDatabase:
      host: postgresql.postgresql.svc.cluster.local
      port: 5432
      user: postgres
      database: ${var.project_name}
      existingSecret: keycloak-postgresql
      existingSecretPasswordKey: POSTGRES_PASSWORD

    # Disable the default PostgreSQL installation
    postgresql:
      enabled: false

    # Service configuration
    service:
      type: ClusterIP
      http:
        enabled: true
      https:
        enabled: true
      ports:
        http: 80
        https: 443

    # Resource limits
    resourcesPreset: "small"
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"

    # Metrics and monitoring
    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        namespace: "monitoring"

    # Pod disruption budget for high availability
    podDisruptionBudget:
      enabled: true
      minAvailable: 1

    livenessProbe:
      enabled: true
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
      successThreshold: 1

    readinessProbe:
      enabled: true
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1

    startupProbe:
      enabled: true
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 60
      successThreshold: 1

    # Affinity for pod scheduling
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                  - key: app.kubernetes.io/name
                    operator: In
                    values:
                      - keycloak
              topologyKey: kubernetes.io/hostname

    # Cache configuration for high availability
    cache:
      enabled: true
      stack: kubernetes
      configFile: "cache-ispn.xml"
      useHeadlessServiceWithAppVersion: false

    # Logging configuration
    logging:
      output: default
      level: DEBUG

    # TLS configuration
    tls:
      enabled: false

    # Network Policy configuration
    networkPolicy:
      enabled: true
      allowExternal: true
      allowExternalEgress: true
      kubeAPIServerPorts: [443, 6443, 8443]
      extraIngress: []
      extraEgress: []
      ingressNSMatchLabels: {}
      ingressNSPodMatchLabels: {}

    # RBAC parameters
    serviceAccount:
      create: true
      name: ""
      automountServiceAccountToken: false
      annotations: {}
      extraLabels: {}

    rbac:
      create: false
      rules: []

    # Mount realm configuration
    extraVolumes:
      - name: realm-config
        configMap:
          name: keycloak-realm-config

    extraVolumeMounts:
      - name: realm-config
        mountPath: /opt/bitnami/keycloak/data/import
    EOT
  ]
}

resource "kubernetes_ingress_v1" "ingress_keycloak" {
  metadata {
    name      = "keycloak-ingress"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer"                      = var.cluster_issuer
      "acme.cert-manager.io/http01-edit-in-place"           = "true"
      "kubernetes.io/ingress.class"                         = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size"         = "20m"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"      = "true"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"       = "128k"
      "nginx.ingress.kubernetes.io/proxy-buffers"           = "4 256k"
      "nginx.ingress.kubernetes.io/proxy-busy-buffers-size" = "256k"
    }
  }
  depends_on = [helm_release.nginx-ingress, helm_release.cert_manager, helm_release.keycloak]

  spec {
    tls {
      hosts = [local.current_domain]
      secret_name = "tls-secret-keycloak"
    }

    rule {
      host = local.current_domain
      http {
        path {
          path_type = "Prefix"
          path      = "/auth"
          backend {
            service {
              name = "keycloak"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map_v1" "keycloak_realm_config" {
  metadata {
    name      = "keycloak-realm-config"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
  }

  data = {
    "master-realm.json"        = <<-EOT
    {
      "realm": "master",
      "enabled": true,
      "sslRequired": "external",
      "registrationAllowed": false,
      "resetPasswordAllowed": true,
      "editUsernameAllowed": false,
      "bruteForceProtected": true,
      "permanentLockout": false,
      "failureFactor": 5,
      "roles": {
        "realm": [
          {
            "name": "user",
            "description": "User role"
          },
          {
            "name": "admin",
            "description": "Administrator role"
          }
        ]
      },
      "clients": [
        {
          "clientId": "microservices-app",
          "enabled": true,
          "clientAuthenticatorType": "client-secret",
          "secret": "${random_password.keycloak_admin_password.result}",
          "redirectUris": [
            "https://${local.current_domain}/*"
          ],
          "webOrigins": [
            "https://${local.current_domain}"
          ],
          "rootUrl": "https://${local.current_domain}",
          "baseUrl": "/",
          "publicClient": false,
          "protocol": "openid-connect",
          "fullScopeAllowed": true,
          "directAccessGrantsEnabled": true
        }
      ]
    }
    EOT
    "microservices-realm.json" = <<-EOT
    {
      "realm": "microservices",
      "enabled": true,
      "sslRequired": "external",
      "registrationAllowed": false,
      "resetPasswordAllowed": true,
      "editUsernameAllowed": false,
      "bruteForceProtected": true,
      "permanentLockout": false,
      "failureFactor": 5,
      "roles": {
        "realm": [
          {
            "name": "user",
            "description": "User role"
          },
          {
            "name": "admin",
            "description": "Administrator role"
          },
          {
            "name": "editor",
            "description": "Editor role for Grafana"
          }
        ]
      },
      "groups": [
        {
          "name": "admin",
          "path": "/admin",
          "attributes": {},
          "realmRoles": ["admin"],
          "clientRoles": {},
          "subGroups": []
        },
        {
          "name": "editor",
          "path": "/editor",
          "attributes": {},
          "realmRoles": ["editor"],
          "clientRoles": {},
          "subGroups": []
        },
        {
          "name": "user",
          "path": "/user",
          "attributes": {},
          "realmRoles": ["user"],
          "clientRoles": {},
          "subGroups": []
        }
      ],
      "users": [
        {
          "username": "admin",
          "enabled": true,
          "emailVerified": true,
          "firstName": "Administrator",
          "lastName": "User",
          "email": "admin@microservices.com",
          "createdTimestamp": 1625097600000,
          "credentials": [
            {
              "type": "password",
              "value": "${random_password.keycloak_admin_password.result}",
              "temporary": false
            }
          ],
          "groups": ["admin"],
          "realmRoles": ["admin"],
          "clientRoles": {}
        },
        {
          "username": "client",
          "enabled": true,
          "emailVerified": true,
          "firstName": "Client",
          "lastName": "User",
          "email": "client@microservice.com",
          "createdTimestamp": 1625097600000,
          "credentials": [
            {
              "type": "password",
              "value": "client",
              "temporary": false
            }
          ],
          "groups": ["user"],
          "realmRoles": ["user"],
          "clientRoles": {}
        },
        {
          "username": "administrator",
          "enabled": true,
          "emailVerified": true,
          "firstName": "Administrator",
          "lastName": "User",
          "email": "admininistrator@microservice.com",
          "createdTimestamp": 1625097600000,
          "credentials": [
            {
              "type": "password",
              "value": "admininistrator",
              "temporary": false
            }
          ],
          "groups": ["admin"],
          "realmRoles": ["admin"],
          "clientRoles": {}
        }
      ],
      "clients": [
        {
          "clientId": "micro-market-frontend",
          "enabled": true,
          "clientAuthenticatorType": "none",
          "redirectUris": [
            "https://${local.current_domain}/*"
          ],
          "webOrigins": [
            "https://${local.current_domain}"
          ],
          "rootUrl": "https://${local.current_domain}",
          "baseUrl": "/",
          "publicClient": true,
          "protocol": "openid-connect",
          "fullScopeAllowed": true,
          "directAccessGrantsEnabled": true,
          "standardFlowEnabled": true,
          "implicitFlowEnabled": false,
          "serviceAccountsEnabled": false,
          "defaultClientScopes": ["web-origins", "profile", "roles", "email", "account", "account-console"],
          "optionalClientScopes": ["address", "phone", "offline_access", "microprofile-jwt"]
        },
        {
          "clientId": "catalog-service",
          "enabled": true,
          "clientAuthenticatorType": "client-secret",
          "secret": "catalog-service-secret",
          "redirectUris": [
            "https://catalog.catalog.svc.cluster.local/*",
            "https://${local.current_domain}/*"
          ],
          "webOrigins": [
            "https://catalog.catalog.svc.cluster.local",
            "https://${local.current_domain}"
          ],
          "rootUrl": "https://catalog.catalog.svc.cluster.local",
          "baseUrl": "/",
          "publicClient": false,
          "protocol": "openid-connect",
          "fullScopeAllowed": true,
          "directAccessGrantsEnabled": true,
          "standardFlowEnabled": true,
          "implicitFlowEnabled": false,
          "serviceAccountsEnabled": true,
          "defaultClientScopes": ["web-origins", "profile", "roles", "email"],
          "optionalClientScopes": ["address", "phone", "offline_access", "microprofile-jwt"]
        },
        {
          "clientId": "audit-service",
          "enabled": true,
          "clientAuthenticatorType": "client-secret",
          "secret": "audit-service-secret",
          "redirectUris": [
            "https://audit.microservices.svc.cluster.local/*",
            "https://${local.current_domain}/*"
          ],
          "webOrigins": [
            "https://audit.microservices.svc.cluster.local",
            "https://${local.current_domain}"
          ],
          "rootUrl": "http://audit-service.microservices.svc.cluster.local",
          "baseUrl": "/",
          "publicClient": false,
          "protocol": "openid-connect",
          "fullScopeAllowed": true,
          "directAccessGrantsEnabled": true,
          "standardFlowEnabled": true,
          "implicitFlowEnabled": false,
          "serviceAccountsEnabled": true,
          "defaultClientScopes": ["web-origins", "profile", "roles", "email"],
          "optionalClientScopes": ["address", "phone", "offline_access", "microprofile-jwt"]
        },
        {
          "clientId": "argocd",
          "enabled": true,
          "clientAuthenticatorType": "client-secret",
          "secret": "${random_password.argo_oidc_client_secret.result}",
          "redirectUris": [
            "https://${local.current_domain}/argocd/auth/callback"
          ],
          "webOrigins": [
            "https://${local.current_domain}"
          ],
          "rootUrl": "https://${local.current_domain}",
          "baseUrl": "/argocd",
          "publicClient": false,
          "protocol": "openid-connect",
          "fullScopeAllowed": false,
          "defaultClientScopes": ["web-origins", "profile", "roles", "email"],
          "optionalClientScopes": ["address", "phone", "offline_access", "microprofile-jwt"],
          "attributes": {
            "access.token.lifespan": "28800",
            "saml.force.post.binding": "false",
            "saml.multivalued.roles": "false",
            "oauth2.device.authorization.grant.enabled": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
            "saml.server.signature.keyinfo.ext": "false",
            "use.refresh.tokens": "true",
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "true",
            "client_credentials.use_refresh_token": "false",
            "saml.client.signature": "false",
            "require.pushed.authorization.requests": "false",
            "saml.assertion.signature": "false",
            "id.token.as.detached.signature": "false",
            "saml.encrypt": "false",
            "saml.server.signature": "false",
            "exclude.session.state.from.auth.response": "false",
            "saml.artifact.binding": "false",
            "saml_force_name_id_format": "false",
            "tls.client.certificate.bound.access.tokens": "false",
            "saml.authnstatement": "false",
            "display.on.consent.screen": "false",
            "saml.onetimeuse.condition": "false"
          }
        },
        {
          "clientId": "grafana",
          "enabled": true,
          "clientAuthenticatorType": "client-secret",
          "secret": "${random_password.grafana_oidc_client_secret.result}",
          "redirectUris": [
            "https://${local.current_domain}/grafana/login/generic_oauth"
          ],
          "webOrigins": [
            "https://${local.current_domain}"
          ],
          "rootUrl": "https://${local.current_domain}/grafana",
          "baseUrl": "/",
          "publicClient": false,
          "protocol": "openid-connect",
          "fullScopeAllowed": false,
          "defaultClientScopes": ["web-origins", "profile", "roles", "email"],
          "optionalClientScopes": ["address", "phone", "offline_access", "microprofile-jwt"],
          "attributes": {
            "access.token.lifespan": "28800",
            "saml.force.post.binding": "false",
            "saml.multivalued.roles": "false",
            "oauth2.device.authorization.grant.enabled": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
            "saml.server.signature.keyinfo.ext": "false",
            "use.refresh.tokens": "true",
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "true",
            "client_credentials.use_refresh_token": "false",
            "saml.client.signature": "false",
            "require.pushed.authorization.requests": "false",
            "saml.assertion.signature": "false",
            "id.token.as.detached.signature": "false",
            "saml.encrypt": "false",
            "saml.server.signature": "false",
            "exclude.session.state.from.auth.response": "false",
            "saml.artifact.binding": "false",
            "saml_force_name_id_format": "false",
            "tls.client.certificate.bound.access.tokens": "false",
            "saml.authnstatement": "false",
            "display.on.consent.screen": "false",
            "saml.onetimeuse.condition": "false"
          }
        }
      ]
    }
    EOT
  }
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = "https://${local.current_domain}/auth"
}

output "keycloak_admin_username" {
  description = "Keycloak admin username"
  value       = "admin"
}

output "keycloak_admin_password" {
  description = "Keycloak admin password"
  value       = random_password.keycloak_admin_password.result
  sensitive   = true
}
