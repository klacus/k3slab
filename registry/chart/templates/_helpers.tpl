{{- define "fullName" -}}
{{- $name := default .Chart.Name .Values.name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app: {{ include "fullName" . }}
{{- end }}

{{- define "serviceAccountName" -}}
{{- default .Values.serviceAccountName (include "fullName" .) }}
{{- end }}