{{- define "demo-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}

{{- define "demo-backend.fullname" -}}
{{- printf "%s" (include "demo-backend.name" .) -}}
{{- end -}}
