package test

import (
	"fmt"
	"log"
	"net/http"
	"os/exec"
	"strings"
)

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func getResourceBearerToken(resource string) string {
	out, err := exec.Command(
		"az",
		"account",
		"get-access-token",
		"--query", "accessToken",
		"--resource", resource,
		"--out", "tsv",
	).Output()

	if err != nil {
		log.Fatal(err.Error())
	}
	bearer := fmt.Sprintf("Bearer %s", out)

	return strings.TrimSuffix(bearer, "\n")
}

func getSubscriptionId() string {
	out, err := exec.Command(
		"az",
		"account",
		"show",
		"--query", "id",
		"--out", "tsv",
	).Output()

	if err != nil {
		log.Fatal(err)
	}
	subscriptionId := string(out)

	return strings.TrimSuffix(subscriptionId, "\n")
}

func getSchema(namespace, name string) (*http.Response, error) {

	client := &http.Client{}
	bearer := getResourceBearerToken("https://" + namespace + ".servicebus.windows.net")

	req, _ := http.NewRequest("GET", "https://"+namespace+".servicebus.windows.net/$schemagroups/metadata/schemas/"+name+"/versions?api-version=2020-09-01-preview", nil)

	req.Header.Add("Authorization", bearer)
	return client.Do(req)
}

func getSchemaGroup(namespace, name string) (*http.Response, error) {

	client := &http.Client{}
	bearer := getResourceBearerToken("https://" + namespace + ".servicebus.windows.net")

	req, _ := http.NewRequest("GET", "https://"+namespace+".servicebus.windows.net/$schemagroups/"+name+"/schemas?api-version=2020-09-01-preview", nil)

	req.Header.Add("Authorization", bearer)
	return client.Do(req)
}
