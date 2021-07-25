# escape=`

ARG PARENT_IMAGE

FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\build

COPY activate-coveo.ps1 c:\build