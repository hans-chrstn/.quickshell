.pragma library

function normalizeNetworkd(payload) {
    const interfaces = Array.isArray(payload?.Interfaces) ? payload.Interfaces : [];
    return interfaces.filter(link => link && (link.Type === "ether" || link.Type === "wlan")).map(link => {
        const addresses = Array.isArray(link.Addresses) ? link.Addresses : [];
        const ipv4 = addresses.find(address => address?.Family === 2 && address?.ScopeString !== "host");
        const route = (Array.isArray(link.Routes) ? link.Routes : []).find(candidate => candidate?.Family === 2 && candidate?.DestinationPrefixLength === 0 && candidate?.GatewayString);
        const dns = (Array.isArray(link.DNS) ? link.DNS : []).find(candidate => candidate?.Family === 2 && candidate?.AddressString);
        const connected = link.CarrierState === "carrier" && (link.OperationalState === "routable" || link.OperationalState === "degraded");
        return {
            id: String(link.Name || ""),
            name: String(link.Name || ""),
            type: link.Type === "ether" ? "wired" : "wifi",
            connected: connected,
            state: String(link.OperationalState || "off"),
            address: String(ipv4?.AddressString || ""),
            gateway: String(route?.GatewayString || ""),
            dns: String(dns?.AddressString || ""),
            hardwareAddress: Array.isArray(link.HardwareAddress) ? link.HardwareAddress.map(part => Number(part).toString(16).padStart(2, "0")).join(":") : "",
            model: String(link.Model || ""),
            carrier: link.CarrierState === "carrier",
            managed: link.AdministrativeState !== "unmanaged"
        };
    }).filter(link => link.id.length > 0).sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name));
}
