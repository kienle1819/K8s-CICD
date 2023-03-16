{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "hello-k8s.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hello-k8s.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hello-k8s.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image name and tag used by the deployment.
*/}}
{{- define "hello-k8s.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
{{- $name := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- $rootless := ternary "-rootless" "" (.Values.image.rootless) -}}
{{- if $registry -}}
  {{- printf "%s/%s:%s%s" $registry $name $tag $rootless -}}
{{- else -}}
  {{- printf "%s:%s%s" $name $tag $rootless -}}
{{- end -}}
{{- end -}}

{{/*
Docker Image Registry Secret Names evaluating values as templates
*/}}
{{- define "hello-k8s.images.pullSecrets" -}}
{{- $pullSecrets := .Values.imagePullSecrets -}}
{{- range .Values.global.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets (dict "name" .) -}}
{{- end -}}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{ toYaml $pullSecrets }}
{{- end }}
{{- end -}}


{{/*
Storage Class
*/}}
{{- define "hello-k8s.persistence.storageClass" -}}
{{- $storageClass := .Values.global.storageClass | default .Values.persistence.storageClass }}
{{- if $storageClass }}
storageClassName: {{ $storageClass | quote }}
{{- end }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "hello-k8s.labels" -}}
helm.sh/chart: {{ include "hello-k8s.chart" . }}
app: {{ include "hello-k8s.name" . }}
{{ include "hello-k8s.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "hello-k8s.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hello-k8s.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "postgresql.dns" -}}
{{- printf "%s-postgresql.%s.svc.%s:%g" .Release.Name .Release.Namespace .Values.clusterDomain .Values.postgresql.global.postgresql.servicePort -}}
{{- end -}}

{{- define "mysql.dns" -}}
{{- printf "%s-mysql.%s.svc.%s:%g" .Release.Name .Release.Namespace .Values.clusterDomain .Values.mysql.service.port | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mariadb.dns" -}}
{{- printf "%s-mariadb.%s.svc.%s:%g" .Release.Name .Release.Namespace .Values.clusterDomain .Values.mariadb.primary.service.port | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "memcached.dns" -}}
{{- printf "%s-memcached.%s.svc.%s:%g" .Release.Name .Release.Namespace .Values.clusterDomain .Values.memcached.service.port | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hello-k8s.default_domain" -}}
{{- printf "%s-hello-k8s.%s.svc.%s" (include "hello-k8s.fullname" .) .Release.Namespace .Values.clusterDomain | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hello-k8s.ldap_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "bindDn") -}}
{{- $_ := set $values "bindDn" "" -}}
{{- end -}}

{{- if not (hasKey $values "bindPassword") -}}
{{- $_ := set $values "bindPassword" "" -}}
{{- end -}}

{{- $flags := list "notActive" "skipTlsVerify" "allowDeactivateAll" "synchronizeUsers" "attributesInBind" -}}
{{- range $key, $val := $values -}}
{{- if and (ne $key "enabled") (ne $key "existingSecret") -}}
{{- if eq $key "bindDn" -}}
{{- printf "--%s \"${hello-k8s_LDAP_BIND_DN_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "bindPassword" -}}
{{- printf "--%s \"${hello-k8s_LDAP_PASSWORD_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "port" -}}
{{- printf "--%s %d " $key ($val | int) -}}
{{- else if has $key $flags -}}
{{- printf "--%s " ($key | kebabcase) -}}
{{- else -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | squote) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "hello-k8s.oauth_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "key") -}}
{{- $_ := set $values "key" (printf "${hello-k8s_OAUTH_KEY_%d}" $idx) -}}
{{- end -}}

{{- if not (hasKey $values "secret") -}}
{{- $_ := set $values "secret" (printf "${hello-k8s_OAUTH_SECRET_%d}" $idx) -}}
{{- end -}}

{{- range $key, $val := $values -}}
{{- if ne $key "existingSecret" -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | quote) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "hello-k8s.public_protocol" -}}
{{- if and .Values.ingress.enabled (gt (len .Values.ingress.tls) 0) -}}
https
{{- else -}}
{{ .Values.hello-k8s.config.server.PROTOCOL }}
{{- end -}}
{{- end -}}

{{- define "hello-k8s.inline_configuration" -}}
  {{- include "hello-k8s.inline_configuration.init" . -}}
  {{- include "hello-k8s.inline_configuration.defaults" . -}}

  {{- $generals := list -}}
  {{- $inlines := dict -}}

  {{- range $key, $value := .Values.hello-k8s.config  }}
    {{- if kindIs "map" $value }}
      {{- if gt (len $value) 0 }}
        {{- $section := default list (get $inlines $key) -}}
        {{- range $n_key, $n_value := $value }}
          {{- $section = append $section (printf "%s=%v" $n_key $n_value) -}}
        {{- end }}
        {{- $_ := set $inlines $key (join "\n" $section) -}}
      {{- end -}}
    {{- else }}
      {{- if or (eq $key "APP_NAME") (eq $key "RUN_USER") (eq $key "RUN_MODE") -}}
        {{- $generals = append $generals (printf "%s=%s" $key $value) -}}
      {{- else -}}
        {{- (printf "Key %s cannot be on top level of configuration" $key) | fail -}}
      {{- end -}}
    {{- end }}
  {{- end }}

  {{- $_ := set $inlines "_generals_" (join "\n" $generals) -}}
  {{- toYaml $inlines -}}
{{- end -}}

{{- define "hello-k8s.inline_configuration.init" -}}
  {{- if not (hasKey .Values.hello-k8s.config "cache") -}}
    {{- $_ := set .Values.hello-k8s.config "cache" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config "server") -}}
    {{- $_ := set .Values.hello-k8s.config "server" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config "metrics") -}}
    {{- $_ := set .Values.hello-k8s.config "metrics" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config "database") -}}
    {{- $_ := set .Values.hello-k8s.config "database" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config "security") -}}
    {{- $_ := set .Values.hello-k8s.config "security" dict -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.repository -}}
    {{- $_ := set .Values.hello-k8s.config "repository" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config "oauth2") -}}
    {{- $_ := set .Values.hello-k8s.config "oauth2" dict -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.inline_configuration.defaults" -}}
  {{- include "hello-k8s.inline_configuration.defaults.server" . -}}
  {{- include "hello-k8s.inline_configuration.defaults.database" . -}}

  {{- if not .Values.hello-k8s.config.repository.ROOT -}}
    {{- $_ := set .Values.hello-k8s.config.repository "ROOT" "/data/git/hello-k8s-repositories" -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.security.INSTALL_LOCK -}}
    {{- $_ := set .Values.hello-k8s.config.security "INSTALL_LOCK" "true" -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config.metrics "ENABLED") -}}
    {{- $_ := set .Values.hello-k8s.config.metrics "ENABLED" .Values.hello-k8s.metrics.enabled -}}
  {{- end -}}
  {{- if .Values.memcached.enabled -}}
    {{- $_ := set .Values.hello-k8s.config.cache "ENABLED" "true" -}}
    {{- $_ := set .Values.hello-k8s.config.cache "ADAPTER" "memcache" -}}
    {{- if not (.Values.hello-k8s.config.cache.HOST) -}}
      {{- $_ := set .Values.hello-k8s.config.cache "HOST" (include "memcached.dns" .) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.inline_configuration.defaults.server" -}}
  {{- if not (hasKey .Values.hello-k8s.config.server "HTTP_PORT") -}}
    {{- $_ := set .Values.hello-k8s.config.server "HTTP_PORT" .Values.service.http.port -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.server.PROTOCOL -}}
    {{- $_ := set .Values.hello-k8s.config.server "PROTOCOL" "http" -}}
  {{- end -}}
  {{- if not (.Values.hello-k8s.config.server.DOMAIN) -}}
    {{- if gt (len .Values.ingress.hosts) 0 -}}
      {{- $_ := set .Values.hello-k8s.config.server "DOMAIN" (index .Values.ingress.hosts 0).host -}}
    {{- else -}}
      {{- $_ := set .Values.hello-k8s.config.server "DOMAIN" (include "hello-k8s.default_domain" .) -}}
    {{- end -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.server.ROOT_URL -}}
    {{- $_ := set .Values.hello-k8s.config.server "ROOT_URL" (printf "%s://%s" (include "hello-k8s.public_protocol" .) .Values.hello-k8s.config.server.DOMAIN) -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.server.SSH_DOMAIN -}}
    {{- $_ := set .Values.hello-k8s.config.server "SSH_DOMAIN" .Values.hello-k8s.config.server.DOMAIN -}}
  {{- end -}}
  {{- if not .Values.hello-k8s.config.server.SSH_PORT -}}
    {{- $_ := set .Values.hello-k8s.config.server "SSH_PORT" .Values.service.ssh.port -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config.server "SSH_LISTEN_PORT") -}}
    {{- if not .Values.image.rootless -}}
      {{- $_ := set .Values.hello-k8s.config.server "SSH_LISTEN_PORT" .Values.hello-k8s.config.server.SSH_PORT -}}
    {{- else -}}
      {{- $_ := set .Values.hello-k8s.config.server "SSH_LISTEN_PORT" "2222" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config.server "START_SSH_SERVER") -}}
    {{- if .Values.image.rootless -}}
      {{- $_ := set .Values.hello-k8s.config.server "START_SSH_SERVER" "true" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config.server "APP_DATA_PATH") -}}
    {{- $_ := set .Values.hello-k8s.config.server "APP_DATA_PATH" "/data" -}}
  {{- end -}}
  {{- if not (hasKey .Values.hello-k8s.config.server "ENABLE_PPROF") -}}
    {{- $_ := set .Values.hello-k8s.config.server "ENABLE_PPROF" false -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.inline_configuration.defaults.database" -}}
  {{- if .Values.postgresql.enabled -}}
    {{- $_ := set .Values.hello-k8s.config.database "DB_TYPE"   "postgres" -}}
    {{- if not (.Values.hello-k8s.config.database.HOST) -}}
      {{- $_ := set .Values.hello-k8s.config.database "HOST"      (include "postgresql.dns" .) -}}
    {{- end -}}
    {{- $_ := set .Values.hello-k8s.config.database "NAME"      .Values.postgresql.global.postgresql.postgresqlDatabase -}}
    {{- $_ := set .Values.hello-k8s.config.database "USER"      .Values.postgresql.global.postgresql.postgresqlUsername -}}
    {{- $_ := set .Values.hello-k8s.config.database "PASSWD"    .Values.postgresql.global.postgresql.postgresqlPassword -}}
  {{- else if .Values.mysql.enabled -}}
    {{- $_ := set .Values.hello-k8s.config.database "DB_TYPE"   "mysql" -}}
    {{- if not (.Values.hello-k8s.config.database.HOST) -}}
      {{- $_ := set .Values.hello-k8s.config.database "HOST"      (include "mysql.dns" .) -}}
    {{- end -}}
    {{- $_ := set .Values.hello-k8s.config.database "NAME"      .Values.mysql.db.name -}}
    {{- $_ := set .Values.hello-k8s.config.database "USER"      .Values.mysql.db.user -}}
    {{- $_ := set .Values.hello-k8s.config.database "PASSWD"    .Values.mysql.db.password -}}
  {{- else if .Values.mariadb.enabled -}}
    {{- $_ := set .Values.hello-k8s.config.database "DB_TYPE"   "mysql" -}}
    {{- if not (.Values.hello-k8s.config.database.HOST) -}}
      {{- $_ := set .Values.hello-k8s.config.database "HOST"      (include "mariadb.dns" .) -}}
    {{- end -}}
    {{- $_ := set .Values.hello-k8s.config.database "NAME"      .Values.mariadb.auth.database -}}
    {{- $_ := set .Values.hello-k8s.config.database "USER"      .Values.mariadb.auth.username -}}
    {{- $_ := set .Values.hello-k8s.config.database "PASSWD"    .Values.mariadb.auth.password -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.init-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraInitVolumeMounts) 0 -}}
    {{- toYaml .Values.extraInitVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.container-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraContainerVolumeMounts) 0 -}}
    {{- toYaml .Values.extraContainerVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "hello-k8s.gpg-key-secret-name" -}}
{{ default (printf "%s-gpg-key" (include "hello-k8s.fullname" .)) .Values.signing.existingSecret }}
{{- end -}}
