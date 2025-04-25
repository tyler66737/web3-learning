package config

import (
	"encoding/json"
	"os"
)

type DBConfig struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Database string `json:"database"`
}

type Config struct {
	SecretKey   string    `json:"secret_key"`
	ServicePort int       `json:"service_port"`
	DB          *DBConfig `json:"db"`
}

func LoadConfig(file string) (*Config, error) {
	bs, err := os.ReadFile(file)
	if err != nil {
		return nil, err
	}
	cfg := Config{}
	if err := json.Unmarshal(bs, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
