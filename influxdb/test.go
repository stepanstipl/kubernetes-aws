package main

import (
	"flag"
	"time"
  "net"

	"github.com/golang/glog"
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

func main() {

	flag.Parse()
	glog.Info("InfluxDB cluster discovery")

  // Wait for the service to come up
	for t := time.Now(); time.Since(t) < WAITFOR_MAX*time.Minute; time.Sleep(10 * time.Second) {
    glog.Infof("Waiting for service moniroting-influxdb %s", time.Since(t))
	}

}
