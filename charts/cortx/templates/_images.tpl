{{/*
Return a valid CORTX image name from parts
{{ include "cortx.images.image" ( dict "image" .Values.path.to.the.image "root" $) }}
*/}}
{{- define "cortx.images.image" -}}
{{- printf "%s/%s:%s" .image.registry .image.repository (default .root.Chart.AppVersion .image.tag) -}}
{{- end -}}

{{/*
Return the Control image name
*/}}
{{- define "cortx.control.image" -}}
{{ include "cortx.images.image" (dict "image" .Values.control.image "root" .) }}
{{- end -}}

{{/*
Return the HA image name
*/}}
{{- define "cortx.ha.image" -}}
{{ include "cortx.images.image" (dict "image" .Values.ha.image "root" .) }}
{{- end -}}

{{/*
Return the Server image name
*/}}
{{- define "cortx.server.image" -}}
{{ include "cortx.images.image" (dict "image" .Values.server.image "root" .) }}
{{- end -}}

{{/*
Return the Client image name
*/}}
{{- define "cortx.client.image" -}}
{{ include "cortx.images.image" (dict "image" .Values.client.image "root" .) }}
{{- end -}}

{{/*
Return the CORTX setup initContainer
{{ include "cortx.containers.setup" ( dict "image" .Values.path.to.the.image "root" $) }}
*/}}
{{- define "cortx.containers.setup" -}}
{{- $image := include "cortx.images.image" (dict "image" .image "root" .root) -}}
- name: cortx-setup
  image: {{ $image }}
  imagePullPolicy: {{ .image.pullPolicy | quote }}
  command:
    - /bin/sh
  args:
    - -c
  {{- if eq $image "ghcr.io/seagate/centos:7" }}
    - sleep $(shuf -i 5-10 -n 1)s
  {{- else }}
    - /opt/seagate/cortx/provisioner/bin/cortx_deploy -f /etc/cortx/solution -c yaml:///etc/cortx/cluster.conf
  {{- end }}
  volumeMounts:
    - name: cortx-configuration
      mountPath: /etc/cortx/solution
    - name: cortx-ssl-cert
      mountPath: /etc/cortx/solution/ssl
    - name: data
      mountPath: /etc/cortx
    - name: configuration-secrets
      mountPath: /etc/cortx/solution/secret
      readOnly: true
  env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
{{- end -}}

{{/*
Return the CORTX Hax container
{{ include "cortx.containers.hax" ( dict "image" .Values.path.to.the.image "root" $) }}
*/}}
{{- define "cortx.containers.hax" -}}
{{- $image := include "cortx.images.image" (dict "image" .image "root" .root) -}}
- name: cortx-hax
  image: {{ $image }}
  imagePullPolicy: {{ .image.pullPolicy | quote }}
  {{- if eq $image "ghcr.io/seagate/centos:7" }}
  command: ["/bin/sleep", "3650d"]
  {{- else }}
  command:
    - /bin/sh
  args:
    - -c
    - /opt/seagate/cortx/hare/bin/hare_setup start --config yaml:///etc/cortx/cluster.conf
  {{- end }}
  volumeMounts:
    - name: cortx-configuration
      mountPath: /etc/cortx/solution
    - name: cortx-ssl-cert
      mountPath: /etc/cortx/solution/ssl
    - name: data
      mountPath: /etc/cortx
  env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
  ports:
  - name: hax-http
    containerPort: {{ .root.Values.hare.hax.ports.http.port | int }}
    protocol: TCP
  - name: hax-tcp
    containerPort: {{ include "cortx.hare.hax.tcpPort" .root | int }}
    protocol: TCP
  {{- if .root.Values.hare.hax.resources }}
  resources: {{- toYaml .root.Values.hare.hax.resources | nindent 4 }}
  {{- end }}
  securityContext:
    allowPrivilegeEscalation: false
{{- end -}}