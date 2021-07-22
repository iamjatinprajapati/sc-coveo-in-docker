# escape=`

# This Dockerfile will build the Sitecore solution and save the build artifacts for use in
# other images, such as 'cm' and 'rendering'. It does not produce a runnable image itself.

ARG BUILD_IMAGE

# In a separate image (as to not affect layer cache), gather all NuGet-related solution assets, so that
# we have what we need to run a cached NuGet restore in the next layer:
# https://stackoverflow.com/questions/51372791/is-there-a-more-elegant-way-to-copy-specific-files-using-docker-copy-to-the-work/61332002#61332002
# This technique is described here:
# https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/building-net-docker-images?view=aspnetcore-3.1#the-dockerfile-1
FROM ${BUILD_IMAGE} AS nuget-prep
COPY *.sln nuget.config Directory.Build.targets Packages.props /nuget/
COPY src/ /temp/
RUN Invoke-Expression 'robocopy C:/temp C:/nuget/src /s /ndl /njh /njs *.csproj *.scproj packages.config'

#Copy Coveo config files
RUN Invoke-Expression 'robocopy C:/temp/Project/SCDockerCoveo.Common.Web/website/App_Config C:/nuget/src /s /ndl /njh /njs Coveo.*.config'

RUN Invoke-Expression 'robocopy C:/temp C:/nuget/src /s /ndl /njh /njs IndexingEncryptionKeys'

FROM ${BUILD_IMAGE} AS builder
ARG BUILD_CONFIGURATION

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
WORKDIR /build

# Copy prepped NuGet artifacts, and restore as distinct layer to take advantage of caching.
COPY --from=nuget-prep ./nuget ./

# Restore NuGet packages
RUN nuget restore -Verbosity quiet

# Copy remaining source code
COPY src/ ./src/

# Copy transforms, retaining directory structure
RUN Invoke-Expression 'robocopy C:\build\src C:\out\transforms /s /ndl /njh /njs *.xdt'

#Copy Coveo config files
RUN Invoke-Expression 'robocopy C:\build\src\Project C:\out\coveo /s /ndl /njh /njs Coveo.*.config'
RUN Invoke-Expression 'robocopy C:\build\src\Project C:\out\coveo /s /ndl /njh /njs IndexingEncryptionKeys'

# Update Coveo files
ARG COVEO_API_KEY
ARG COVEO_INDEXING_ENDPOINT_URI
ARG COVEO_ORGANIZATION_ID
ARG COVEO_CLOUD_PLATFORM_URI
ARG COVEO_SEARCH_API_KEY
ARG COVEO_SITECORE_USERNAME
ARG COVEO_SITECORE_USER_PASSWORD
ARG COVEO_FARM_NAME

ENV COVEO_API_KEY=${COVEO_API_KEY}
ENV COVEO_INDEXING_ENDPOINT_URI=${COVEO_INDEXING_ENDPOINT_URI}
ENV COVEO_ORGANIZATION_ID=${COVEO_ORGANIZATION_ID}
ENV COVEO_CLOUD_PLATFORM_URI=${COVEO_CLOUD_PLATFORM_URI}
ENV COVEO_SEARCH_API_KEY=${COVEO_SEARCH_API_KEY}
ENV COVEO_SITECORE_USERNAME=${COVEO_SITECORE_USERNAME}
ENV COVEO_SITECORE_USER_PASSWORD=${COVEO_SITECORE_USER_PASSWORD}
ENV COVEO_FARM_NAME=${COVEO_FARM_NAME}

COPY update-coveo-files.ps1 C:\out

RUN C:\out\update-coveo-files.ps1 -configPath C:\out\coveo

#RUN Get-ChildItem -Path C:\build\src -Include Coveo*.config -Recurse | ForEach-Object { Write-Host $_.FullName }

# Ensure deploy folder exist to prevent errors on initial build
RUN mkdir ./docker/deploy/platform

# Build the solution to generate build artifacts
## assumes that the msbuild property <SitecoreRoleType>platform|rendering</SitecoreRoleType> is used to target deploy folders 
RUN Get-ChildItem *.sln | %{  msbuild $_.FullName /p:Configuration=$env:BUILD_CONFIGURATION /m /p:DeployOnBuild=true /p:IsLocalDockerDeploy=true }

#RUN Get-ChildItem * -Include Coveo*.config -Recurse | ForEach-Object { Write-Host $_.FullName}

# Save the artifacts for copying into other images (see 'cm' and 'rendering' Dockerfiles).
FROM mcr.microsoft.com/windows/nanoserver:1809
WORKDIR /artifacts
COPY --from=builder /build/docker/deploy/ ./
COPY --from=builder C:\out\transforms .\transforms\
COPY --from=builder C:\out\coveo\SCDockerCoveo.Common.Web\website .\coveo\