FROM lightningnetwork/golang-alpine:latest

COPY . /go/src/github.com/evgeniy-scherbina/calc

WORKDIR /go/src/github.com/evgeniy-scherbina/calc
RUN go install ./services/add
RUN go install ./services/sub
RUN go install ./services/mul
RUN go install ./services/div