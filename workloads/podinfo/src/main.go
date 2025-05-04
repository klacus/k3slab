package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
	"os/user"
	"runtime"

	"github.com/gin-gonic/gin"
)

type Groups struct {
	Name string `json:"name"`
	GID  string `json:"gid"`
}

type IPAddresses struct {
	Family  string `json:"family"`
	Type    string `json:"type"`
	Address string `json:"address"`
}

type Request struct {
	RemoteAddress string   `json:"remoteaddress"`
	RequestURI    string   `json:"remoteuri"`
	Referrer      string   `json:"referrer"`
	Scheme        string   `json:"scheme"`
	Method        string   `json:"method"`
	Host          string   `json:"host"`
	Path          string   `json:"path"`
	Protocol      string   `json:"protocol"`
	RawQuery      string   `json:"rawquery"`
	URL           string   `json:"url"`
	UserAgent     string   `json:"useragent"`
	Headers       []string `json:"headers"`
}

type KubernetesInfo struct {
	Namespace string `json:"namespace"`
	Name      string `json:"name"`
	NodeName  string `json:"nodename"`
}

type ProcessInfo struct {
	PID            int            `json:"pid"`
	CPUs           int            `json:"cpus"`
	OS             string         `json:"os"`
	Architecture   string         `json:"architecture"`
	Username       string         `json:"username"`
	UserID         string         `json:"userid"`
	Groups         []Groups       `json:"groups"`
	Executable     string         `json:"executable"`
	ExecutablePath string         `json:"executablepath"`
	WorkingDir     string         `json:"workingdir"`
	Args           []string       `json:"args"`
	Kubernetes     KubernetesInfo `json:"kubernetes"`
}

type HostInfo struct {
	Hostname    string        `json:"hostname"`
	FQDN        string        `json:"fqdn"`
	IPAddresses []IPAddresses `json:"ipaddresses"`
}

type podinfo struct {
	Process ProcessInfo `json:"processifo"`
	Host    HostInfo    `json:"hostinfo"`
	Request Request     `json:"request"`
}

var cachedProcessInfo ProcessInfo
var cachedHostInfo HostInfo

func init() {
	setProcessInfo()
	setHostInfo()
}

func main() {
	router := gin.Default()
	router.GET("/", getID)
	router.GET("/id", getID)
	router.GET("/healthz", health)
	router.Run(":8080")
}

func getID(c *gin.Context) {
	var podInfo podinfo

	podInfo.Process = cachedProcessInfo
	podInfo.Host = cachedHostInfo

	podInfo.Request.RemoteAddress = c.Request.RemoteAddr
	podInfo.Request.RequestURI = c.Request.RequestURI
	podInfo.Request.Referrer = c.Request.Referer()
	podInfo.Request.Method = c.Request.Method
	podInfo.Request.Protocol = c.Request.Proto
	podInfo.Request.Scheme = c.Request.URL.Scheme
	podInfo.Request.Host = c.Request.Host
	podInfo.Request.Path = c.Request.URL.Path
	podInfo.Request.RawQuery = c.Request.URL.RawQuery

	podInfo.Request.Headers = make([]string, 0, len(c.Request.Header)) // Pre-allocate
	for key, values := range c.Request.Header {
		cHeader := fmt.Sprintf("%s: %s", key, values)
		podInfo.Request.Headers = append(podInfo.Request.Headers, cHeader)
	}

	// In a real workload for production usage use c.JSON instead to save on CPU usage.
	c.IndentedJSON(http.StatusOK, podInfo)
}

func health(c *gin.Context) {
	c.Status(http.StatusOK)
}

func setProcessInfo() {
	cachedProcessInfo.PID = os.Getpid()
	cachedProcessInfo.CPUs = runtime.NumCPU()
	cachedProcessInfo.OS = runtime.GOOS
	cachedProcessInfo.Architecture = runtime.GOARCH

	cachedProcessInfo.Kubernetes.Namespace = os.Getenv("K8S_POD_NAMESPACE")
	cachedProcessInfo.Kubernetes.Name = os.Getenv("K8S_POD_NAME")
	cachedProcessInfo.Kubernetes.NodeName = os.Getenv("K8S_NODE_NAME")

	currentUser, err := user.Current()
	if err != nil {
		fmt.Println("Error getting current user:", err)
		return
	}
	cachedProcessInfo.Username = currentUser.Username
	cachedProcessInfo.UserID = currentUser.Uid

	cachedProcessInfo.Groups = make([]Groups, 0, 10) // Pre-allocate
	groups, err := currentUser.GroupIds()
	if err != nil {
		fmt.Println("Error getting group IDs:", err)
		return
	}
	for _, gid := range groups {
		group, err := user.LookupGroupId(gid)
		if err != nil {
			fmt.Println("Error looking up group:", err)
			continue
		}
		cachedProcessInfo.Groups = append(cachedProcessInfo.Groups, Groups{
			Name: group.Name,
			GID:  fmt.Sprint(group.Gid),
		})
	}

	cachedProcessInfo.Executable = os.Args[0] // os.Args[0] is the executable name
	cachedProcessInfo.ExecutablePath, _ = os.Executable()
	cachedProcessInfo.WorkingDir, _ = os.Getwd()
	cachedProcessInfo.Args = os.Args
}

func setHostInfo() {
	hostname, err := os.Hostname()
	if err != nil {
		fmt.Println("Error getting hostname:", err)
		return
	}
	cachedHostInfo.Hostname = hostname

	fqdn, err := net.LookupCNAME(hostname)
	if err == nil {
		cachedHostInfo.FQDN = fqdn
	}

	ips, err := net.InterfaceAddrs()
	if err != nil {
		fmt.Println("Error getting network interface addresses:", err)
		return
	}
	cachedHostInfo.IPAddresses = make([]IPAddresses, 0, len(ips)) // Pre-allocate
	var ipa IPAddresses
	for _, addr := range ips {
		// Check if the address is an IPNet (IP network)
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				ipa.Family = "IPv4"
			} else if ipnet.IP.To16() != nil {
				ipa.Family = "IPv6"
			}
			// ipa.Address = ipnet.IP.String()
			ipa.Address = ipnet.String()
			ipa.Type = "IP Network"
		} else if ipaddr, ok := addr.(*net.IPAddr); ok && !ipaddr.IP.IsLoopback() {
			if ipaddr.IP.To4() != nil {
				ipa.Family = "IPv4"
			} else if ipaddr.IP.To16() != nil {
				ipa.Family = "IPv6"
			}
			// ipa.Address = ipaddr.IP.String()
			ipa.Address = ipaddr.String()
			ipa.Type = "IP Address"
		} else {
			ipa.Address = addr.String()
		}
		cachedHostInfo.IPAddresses = append(cachedHostInfo.IPAddresses, ipa)
	}
}
