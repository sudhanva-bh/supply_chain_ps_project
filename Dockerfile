FROM softwaretree/gilhari

# Switch to root to install wget
USER root
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/supply_chain_service

# Download the Microsoft SQL Server JDBC driver
RUN wget https://github.com/microsoft/mssql-jdbc/releases/download/v12.4.2/mssql-jdbc-12.4.2.jre8.jar -P /node/node_modules/jdxnode/external_libs/

# Add application files
ADD bin ./bin
ADD config ./config
ADD gilhari_service.config .

EXPOSE 8081 

CMD ["node", "/node/node_modules/gilhari_rest_server/gilhari_rest_server.js", "gilhari_service.config"]
