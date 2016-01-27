package main

import (
	"flag"
	"fmt"
	"strings"
	"time"
  "net"
  "math/rand"

	"github.com/golang/glog"
	"k8s.io/kubernetes/pkg/api"
	client "k8s.io/kubernetes/pkg/client/unversioned"
)

const WAITFOR_MAX = 3
const WAITFOR_MIN = 1

func getMyIP() string {
  addrs, err := net.InterfaceAddrs()
  if err != nil {
    glog.Fatalf("Failed to get my IP: %v", err)
  }
  for _, address := range addrs {
    // check the address type and if it is not a loopback the display it
    if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
      if ipnet.IP.To4() != nil {
	      glog.Infof("My IP is %s", ipnet.IP)
        return ipnet.IP.String()
      }
    }
  }
  return ""
}

func flattenSubsets(subsets []api.EndpointSubset) []string {
	ips := []string{}
	for _, ss := range subsets {
		for _, addr := range ss.Addresses {
      ips = append(ips, addr.IP)
		}
	}
	return ips
}

func main() {

	flag.Parse()
	glog.Info("InfluxDB cluster discovery")

  myip := getMyIP()

	c, err := client.NewInCluster()
	if err != nil {
		glog.Fatalf("Failed to make client: %v", err)
	}

	var influxdb *api.Service
  // Wait for the service to come up
	for t := time.Now(); time.Since(t) < WAITFOR_MAX*time.Minute; time.Sleep(10 * time.Second) {
    glog.Infof("Waiting for service moniroting-influxdb %s", time.Since(t))
		influxdb, err = c.Services(api.NamespaceSystem).Get("monitoring-influxdb")
		if err == nil {
			break
		}
	}

	if influxdb == nil {
		glog.Warningf("Failed to find the monitoring-influxdb service: %v", err)
		return
	}

	var endpoints *api.Endpoints
	addrs := []string{}
	// Wait for some endpoints.
	count := 0
	for t := time.Now(); time.Since(t) < time.Duration(rand.Intn(WAITFOR_MAX-WAITFOR_MIN)+WAITFOR_MIN)*time.Minute; time.Sleep(10 * time.Second) {
    glog.Infof("Waiting for service endpoints %s", time.Since(t))
		endpoints, err = c.Endpoints(api.NamespaceSystem).Get("monitoring-influxdb")
		if err != nil {
			continue
		}
		addrs = flattenSubsets(endpoints.Subsets)

    for i, element := range addrs {
      if element == myip {
        addrs = append(addrs[:i], addrs[i+1:]...)
      }
    }

		glog.Infof("Found %s", addrs)
		if len(addrs) > 0 && len(addrs) == count {
			break
		}
		count = len(addrs)
	}
	// If there was an error finding endpoints then log a warning and quit.
	if err != nil {
		glog.Warningf("Error finding endpoints: %v", err)
		return
	}

	glog.Infof("Endpoints = %s", addrs)
	fmt.Printf("%s", strings.Join(addrs, ", "))
}
