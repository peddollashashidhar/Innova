{{- define "angular-frontend.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}

{{- define "angular-frontend.fullname" -}}
{{- printf "%s" (include "angular-frontend.name" .) -}}
{{- end -}}
