# Build stage for all services
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Copy the parent pom.xml
COPY pom.xml .

# Copy all service pom files
COPY eureka-server/pom.xml eureka-server/
COPY api-gateway/pom.xml api-gateway/
COPY Ambulance_Service/pom.xml Ambulance_Service/
COPY dispatch-coordination-service/pom.xml dispatch-coordination-service/
COPY hospital-management-service/pom.xml hospital-management-service/
COPY route-optimization-service/pom.xml route-optimization-service/

# Copy source code for all services
COPY eureka-server/src eureka-server/src
COPY api-gateway/src api-gateway/src
COPY Ambulance_Service/src Ambulance_Service/src
COPY dispatch-coordination-service/src dispatch-coordination-service/src
COPY hospital-management-service/src hospital-management-service/src
COPY route-optimization-service/src route-optimization-service/src

# Build each service individually with verbose output
RUN set -x && \
    echo "Building Eureka Server..." && \
    cd eureka-server && mvn clean package -DskipTests && \
    echo "Eureka Server target contents:" && ls -la target/ && cd .. && \
    echo "Building API Gateway..." && \
    cd api-gateway && mvn clean package -DskipTests && \
    echo "API Gateway target contents:" && ls -la target/ && cd .. && \
    echo "Building Ambulance Service..." && \
    cd Ambulance_Service && mvn clean package -DskipTests && \
    echo "Ambulance Service target contents:" && ls -la target/ && cd .. && \
    echo "Building Dispatch Service..." && \
    cd dispatch-coordination-service && mvn clean package -DskipTests && \
    echo "Dispatch Service target contents:" && ls -la target/ && cd .. && \
    echo "Building Hospital Service..." && \
    cd hospital-management-service && mvn clean package -DskipTests && \
    echo "Hospital Service target contents:" && ls -la target/ && cd .. && \
    echo "Building Route Service..." && \
    cd route-optimization-service && mvn clean package -DskipTests && \
    echo "Route Service target contents:" && ls -la target/

# Runtime stage for Eureka Server
FROM eclipse-temurin:17-jre-alpine AS eureka-server
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8761
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8761/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Runtime stage for API Gateway
FROM eclipse-temurin:17-jre-alpine AS api-gateway
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/api-gateway/target/api-gateway.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8888
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8888/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Runtime stage for Ambulance Service
FROM eclipse-temurin:17-jre-alpine AS ambulance-service
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/Ambulance_Service/target/Ambulance_Service-0.0.1-SNAPSHOT.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8095
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8095/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Runtime stage for Dispatch Service
FROM eclipse-temurin:17-jre-alpine AS dispatch-service
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/dispatch-coordination-service/target/dispatch-coordination-service-0.0.1-SNAPSHOT.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8096
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8096/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Runtime stage for Hospital Service
FROM eclipse-temurin:17-jre-alpine AS hospital-service
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/hospital-management-service/target/hospital-management-service-0.0.1-SNAPSHOT.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8093
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8093/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Runtime stage for Route Service
FROM eclipse-temurin:17-jre-alpine AS route-service
RUN apk add --no-cache curl && \
    addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder --chown=spring:spring /build/route-optimization-service/target/route-optimization-service-0.0.1-SNAPSHOT.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8084
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8084/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
