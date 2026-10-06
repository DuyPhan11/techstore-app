# Stage 1: Build the JAR package
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copy pom.xml and source code
COPY pom.xml .
COPY src ./src

# Build executable jar skipping unit tests
RUN mvn clean package -DskipTests

# Stage 2: Runtime image with lightweight JRE 21
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Create a non-privileged user
RUN addgroup -S techstore && adduser -S techstore -G techstore
USER techstore

# Copy jar artifact from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Memory optimization for cloud environments (Render Free Tier 512MB RAM)
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
