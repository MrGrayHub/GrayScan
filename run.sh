#!/bin/bash

SCRIPT_DIR="."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    echo -e "${YELLOW}[GrayScan] Օգտագործում: gmap <թիրախ> [ընտրանքներ]${NC}"
    echo ""
    echo -e "${YELLOW}[GrayScan] Ընտրանքներ:${NC}"
    echo -e "${YELLOW}[GrayScan]  -h, --help           Ցույց տալ այս օգնության հաղորդագրությունը և դուրս գալ${NC}"
    echo -e "${YELLOW}[GrayScan]  -p, --ports <ports>  Սահմանել սկանավորման պորտերը (օր. 22,80,443 կամ 1-1024, առավելագույնը 65535)${NC}"
    echo -e "${YELLOW}[GrayScan]  -s, --service        Փորձել հայտնաբերել բաց պորտերի վրա աշխատող ծառայությունները${NC}"
    echo -e "${YELLOW}[GrayScan]  -o, --os             Փորձել հայտնաբերել օպերացիոն համակարգը${NC}"
    echo -e "${YELLOW}[GrayScan]  -v, --verbose        Միացնել մանրամասն ելքը${NC}"
    echo -e "${YELLOW}[GrayScan]  -f, --format <type>  Սահմանել ելքի ձևաչափը (txt, json, csv)${NC}"
    echo -e "${YELLOW}[GrayScan]  -t <timeout>         Սահմանել timeout-ի ժամանակը (1, 2, 3, 4 վայրկյան)${NC}"
    echo -e "${YELLOW}[GrayScan]  -save                Պահպանել ելքը gray_scan-ում${NC}"
}

ports=""
service=false
os=false
verbose=false
format="txt"
timeout=1
save_output_flag=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) 
            show_help
            exit 0 
            ;;
        -p|--ports) 
            ports="$2" 
            shift 
            ;;
        -s|--service) 
            service=true 
            ;;
        -o|--os) 
            os=true 
            ;;
        -v|--verbose) 
            verbose=true 
            ;;
        -f|--format) 
            format="$2" 
            shift 
            ;;
        -t) 
            timeout="$2"
            if [[ $timeout -lt 1 || $timeout -gt 4 ]]; then
                echo -e "${RED}[GrayScan] -t պարամետրը չի կարող լինել 1-ից փոքր կամ 4-ից մեծ:${NC}"
                exit 1
            fi
            shift 
            ;;
        -save) 
            save_output_flag=true 
            ;;
        *) 
            target="$1" 
            ;;
    esac
    shift
done

if [[ -z "$target" ]]; then
    echo -e "${RED}[GrayScan] Սխալ: Թիրախը պարտադիր է:${NC}"
    show_help
    exit 1
fi
echo -e "${CYAN}Դուք ընտրել եք:${NC}"
if [[ "$ports" != "" ]]; then echo -e "${GREEN}[+port+]${NC} Պորտեր: $ports"; fi
if [[ "$service" == true ]]; then echo -e "${GREEN}[+service+]${NC} Սերվիսի հայտնաբերման ռեժիմը միացված է"; fi
if [[ "$os" == true ]]; then echo -e "${GREEN}[+os+]${NC} ՕՀ Հայտնաբերման ռեժիմը միացված է"; fi
if [[ "$verbose" == true ]]; then echo -e "${GREEN}[+verbose+]${NC} Verbose Mode Enabled"; fi
if [[ "$save_output_flag" == true ]]; then echo -e "${GREEN}[+save+]${NC} Պահպանել արդյունքը միացված է"; fi
if [[ "$timeout" != 1 ]]; then echo -e "${GREEN}[+timeout+]${NC} Socket Timeout: $timeout վայրկյան"; fi

resolve_domain() {
    local domain=$1
    dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
}


expand_cidr() {
    local cidr=$1
    local ip base_ip mask i

    ip=$(echo $cidr | cut -d '/' -f1)
    mask=$(echo $cidr | cut -d '/' -f2)

    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    base_ip=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))

    net_addr=$(( base_ip & ((2**32 - 1) << (32 - mask)) ))

    host_bits=$(( 32 - mask ))
    num_hosts=$(( 2 ** host_bits ))

    for (( i=0; i<num_hosts; i++ )); do
        ip=$(( net_addr + i ))
        echo "$(( (ip >> 24) & 255 )).$(( (ip >> 16) & 255 )).$(( (ip >> 8) & 255 )).$(( ip & 255 ))"
    done
}

is_reachable() {
    local ip=$1
    ping -c 1 -W 1 "$ip" &> /dev/null
    return $?
}

if [[ "$target" == */* ]]; then
    echo -e "${GREEN}[GrayScan] Ընդլայնում է CIDR նշումը: $target${NC}"
    ip_list=$(expand_cidr "$target")
elif [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ip_list=$target
else
    echo -e "${GREEN}[GrayScan] Դոմենի լուծում: $target${NC}"
    ip_list=$(resolve_domain "$target")
fi

for ip in $ip_list; do
    if is_reachable "$ip"; then
        echo -e "${GREEN}[GrayScan] IP $ip հասանելի է: Սկսում է սկանավորումը...${NC}"
        python3 "/opt/gray_scan_project/scan.py" "$ip" "$ports" "$service" "$os" "$verbose" "$format" "$save_output_flag" "$timeout"
    else
        if [[ $verbose == true ]]; then
            echo -e "${RED}[GrayScan] IP $ip հասանելի չէ: Բաց թողնել սկանավորումը:${NC}"
        fi    
    fi
done