# escape=`

ARG PARENT_IMAGE
ARG SXA_IMAGE
ARG SPE_IMAGE
ARG COVEO_ASSET
ARG COVEO_SXA_ASSET
ARG HEADLESS_SERVICES_IMAGE

FROM ${SPE_IMAGE} as spe
FROM ${SXA_IMAGE} as sxa
FROM ${COVEO_ASSET} as coveo
FROM ${COVEO_SXA_ASSET} as coveosxa
FROM ${HEADLESS_SERVICES_IMAGE} AS headless_services
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Add SPE module
COPY --from=spe \module\db \spe_data
RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\spe_data; `
    Remove-Item -Path C:\spe_data -Recurse -Force;

# Add SXA module
COPY --from=sxa \module\db \sxa_data
RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\sxa_data; `
    Remove-Item -Path C:\sxa_data -Recurse -Force;

# Add Coveo module
COPY --from=coveo \module\db \coveo_data
RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\coveo_data; `
    Remove-Item -Path C:\coveo_data -Recurse -Force;

# Add Coveo SXA module
COPY --from=coveosxa \module\db \coveo_data
RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\coveo_data; `
    Remove-Item -Path C:\coveo_data -Recurse -Force;

# Add JSS module
COPY --from=headless_services \module\db \jss_data
RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\jss_data; `
    Remove-Item -Path C:\jss_data -Recurse -Force;