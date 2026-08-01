#!/bin/bash
sg docker -c "docker inspect backend-backend-1 --format '{{range .Mounts}}SRC={{.Source}} DST={{.Destination}} TYPE={{.Type}} RO={{.RW}}{{println}}{{end}}'" 2>&1
