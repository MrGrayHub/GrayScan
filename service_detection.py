
class ServiceDetector:
    def __init__(self, services_file='/opt/gray_scan_project/nmap-services'):
        self.services = self.load_services(services_file)

    def load_services(self, services_file):
        services = {}
        with open(services_file, 'r') as file:
            for line in file:
                if line.startswith('#') or not line.strip():
                    continue
                parts = line.split()
                if len(parts) >= 2:
                    service_name = parts[0]
                    port_protocol = parts[1]
                    port, protocol = port_protocol.split('/')
                    additional_info = " ".join(parts[2:])
                    services[(int(port), protocol)] = f"{service_name} {port_protocol} {additional_info}"
        return services

    def detect_service(self, port, protocol='tcp'):
        return self.services.get((port, protocol), 'unknown')