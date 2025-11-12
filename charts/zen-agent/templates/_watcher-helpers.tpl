{{/* Watcher fullname */}}
{{- define "zen-agent.watcher.fullname" -}}
{{ include "zen-agent.fullname" . }}-zen-watcher
{{- end -}}

{{/* Watcher labels */}}
{{- define "zen-agent.watcher.labels" -}}
app.kubernetes.io/name: zen-watcher
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "1.0.0"
app.kubernetes.io/component: watcher
helm.sh/chart: zen-watcher-1.0.0
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Watcher selector labels */}}
{{- define "zen-agent.watcher.selectorLabels" -}}
app.kubernetes.io/name: zen-watcher
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Watcher service account name */}}
{{- define "zen-agent.watcher.serviceAccountName" -}}
{{ include "zen-agent.watcher.fullname" . }}
{{- end -}}

{{/* zen-agent fullname */}}
{{- define "zen-agent.fullname" -}}
zen-agent
{{- end -}}

