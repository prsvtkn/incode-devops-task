FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine

WORKDIR /app

COPY ./out/small-demo-app .

ENTRYPOINT ["dotnet", "Foo.Bar.dll"]

EXPOSE 5001
