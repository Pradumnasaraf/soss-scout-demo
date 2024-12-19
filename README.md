# SOSS Scout Demo

The repository demonstrates the use of Docker Scout in a CI/CD pipeline to examine vulnerabilities in container images. This demo was presented at Secure Open Source Software (SOSS) Community Days India 2024.

## Docker Scout Workflow

```yaml
name: Docker

on:
  push:
    tags: [ "*" ]
    branches:
      - 'main'
  pull_request:
    branches: [ "**" ]

env:
  REGISTRY: docker.io
  IMAGE_NAME: 'Pradumnasaraf/soss-scout-demo' # github.repository
  SHA: ${{ github.event.pull_request.head.sha || github.event.after }}
  COMPARE_TAG: latest

jobs:
  build:

    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
      pull-requests: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          ref: ${{ env.SHA }}

      - name: Setup Docker buildx
        uses: docker/setup-buildx-action@v2.5.0
        with:
          driver-opts: |
            image=moby/buildkit:v0.10.6

      # Login against a Docker registry
      - name: Log into registry ${{ env.REGISTRY }}
        uses: docker/login-action@v2.1.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.DOCKER_USER }}
          password: ${{ secrets.DOCKER_PAT }}

      # Extract metadata (tags, labels) for Docker
      # https://github.com/docker/metadata-action
      - name: Extract Docker metadata
        id: meta
        uses: docker/metadata-action@v4.4.0
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          labels: |
            org.opencontainers.image.revision=${{ env.SHA }}
          tags: |
            type=edge,branch=$repo.default_branch
            type=semver,pattern=v{{version}}
            type=sha,prefix=,suffix=,format=short

      # Build and push Docker image with Buildx (don't push on PR)
      - name: Build and push Docker image
        id: build-and-push
        uses: docker/build-push-action@v4.0.0
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Docker Scout
        id: docker-scout
        if: ${{ github.event_name == 'pull_request' }}
        uses: docker/scout-action@v1
        with:
          command: compare, recommendations
          image: ${{ steps.meta.outputs.tags }}
          to: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.COMPARE_TAG }}
          ignore-unchanged: true
          only-severities: critical,high
          write-comment: true
          github-token: ${{ secrets.GITHUB_TOKEN }} # to be able to write the comment
``` 

## Dockerfile 

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o /app .

FROM alpine:3.17.6
# FROM alpine:3.12.5
# FROM alpine:3.21.0
EXPOSE 8080
COPY --from=builder /app /bin/app
CMD ["bin/app"]
```

## Resources

- [Slides](./slides.pdf)
- [Recording](https://youtu.be/hRp4PaZ6FS4?si=W_YyZ9K7nAe3FDgY)
