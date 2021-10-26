FROM mcr.microsoft.com/dotnet/sdk:6.0

COPY ./* /home/

WORKDIR /home

RUN dotnet build

ENTRYPOINT [ "dotnet", "run" ]
