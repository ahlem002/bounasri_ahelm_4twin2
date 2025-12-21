# Dockerfile
# Étape 1: Build
FROM eclipse-temurin:17-jdk-alpine as builder
WORKDIR /app

# Installer bash pour Gradle
RUN apk add --no-cache bash

# Copier les fichiers de build
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
RUN chmod +x ./gradlew

# Télécharger les dépendances (cache layer)
RUN ./gradlew dependencies --no-daemon

# Copier le code source
COPY src src

# Construire l'application
RUN ./gradlew bootJar -x test --no-daemon

# Étape 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Définir le fuseau horaire
RUN apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Créer un utilisateur non-root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copier le JAR depuis l'étape de build
COPY --from=builder /app/build/libs/*.jar app.jar

# Exposition du port
EXPOSE 8080

# Commande d'exécution
ENTRYPOINT ["java", "-jar", "/app/app.jar"]