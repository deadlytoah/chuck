# Makefile
BINDIR=bin
BINARY_NAME=bootstrap
BUCKET=chuck.overcomingsh.in
GOOS=linux
GOARCH=arm64
SRCS=$(shell find . -name \*.go)
PKG=.

build: $(BINDIR)/$(BINARY_NAME)

zip: $(BINDIR)/$(BINARY_NAME).zip

$(BINDIR)/$(BINARY_NAME): $(SRCS)
	mkdir -p $(BINDIR)
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o $(BINDIR)/$(BINARY_NAME) $(PKG)

$(BINDIR)/$(BINARY_NAME).zip: $(BINDIR)/$(BINARY_NAME)
	zip -j $(BINDIR)/$(BINARY_NAME).zip $(BINDIR)/$(BINARY_NAME)

deploy: $(BINDIR)/$(BINARY_NAME).zip
	aws s3 cp $(BINDIR)/$(BINARY_NAME).zip s3://$(BUCKET)/lambda/$(BINARY_NAME).zip

update: $(BINDIR)/$(BINARY_NAME).zip
	aws lambda update-function-code --function-name chuck-api --zip-file fileb://./bin/$(BINARY_NAME).zip

clean:
	rm -f $(BINDIR)/$(BINARY_NAME) $(BINDIR)/$(BINARY_NAME).zip
