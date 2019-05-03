package main

// Note: code extracted from https://github.com/grafana/grafana
// License (grafana original license information)
// Grafana is distributed under Apache 2.0 License.

import (
	"os"
	"fmt"
	"strconv"
	"encoding/base64"
	"encoding/json"
)

type ApiKeyJson struct {
	Key   string `json:"k"`
	Name  string `json:"n"`
	OrgId int64  `json:"id"`
}

type KeyGenResult struct {
	HashedKey    string
	ClientSecret string
}

func main() {
	if len(os.Args) != 3 {
		panic("Required arguments: <orgId> <name>")
	}
	orgId, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}
	name := os.Args[2]
	jsonKey := ApiKeyJson{}

	jsonKey.OrgId = orgId
	jsonKey.Name = name
	jsonKey.Key = GetRandomString(32)

	result := KeyGenResult{}
	result.HashedKey = EncodePassword(jsonKey.Key, name)

	jsonString, _ := json.Marshal(jsonKey)

	result.ClientSecret = base64.StdEncoding.EncodeToString(jsonString)
	fmt.Printf("HashedKey=%v\n", result.HashedKey)
	fmt.Printf("ClientSecret=%v\n", result.ClientSecret)
}