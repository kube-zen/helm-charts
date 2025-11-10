{{/*
Expand the name of the chart.
*/}}
{{- define "zen-watcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "zen-watcher.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "zen-watcher.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zen-watcher.labels" -}}
helm.sh/chart: {{ include "zen-watcher.chart" . }}
{{ include "zen-watcher.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zen-watcher.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zen-watcher.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zen-watcher.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zen-watcher.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for PodSecurityPolicy
*/}}
{{- define "zen-watcher.pspApiVersion" -}}
{{- if semverCompare ">=1.25-0" .Capabilities.KubeVersion.GitVersion -}}
policy/v1beta1
{{- else -}}
policy/v1beta1
{{- end -}}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "zen-watcher.kubeVersion" -}}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersionOverride }}
{{- end }}

{{/*
Return namespace
*/}}
{{- define "zen-watcher.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride }}
{{- end }}


