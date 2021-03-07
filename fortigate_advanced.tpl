config system global
    set hostname ${hostname}
    set timezone 04
    set admintimeout 60
end

config vpn ipsec phase1-interface
    edit "HUB"
        set interface "port1"
        set type dynamic
        set ike-version 2
        set keylife 28800
        set peertype any
        set net-device disable
        set proposal aes256-sha256
        set add-route disable
        set auto-discovery-sender enable
        set tunnel-search nexthop
        set psksecret ${pre_shared_key}
        set dpd-retryinterval 5
        set dpd on-idle        
        set mode-cfg enable
        set assign-ip enable
        set assign-ip-from range
        set ipv4-start-ip 172.16.1.10
        set ipv4-end-ip 172.16.1.100
        set ipv4-netmask 255.255.255.0        
    next
end
config vpn ipsec phase2-interface
    edit "HUB"
        set phase1name "HUB"
        set proposal aes256-sha256
        set keylifeseconds 1800
    next
end

config system interface
    edit port1
        set alias public
        set mode dhcp
        set allowaccess ping https ssh fgfm
    next
    edit port2
        set alias private
        set mode dhcp
        set allowaccess ping https ssh fgfm
        set defaultgw disable
    next
    edit "HUB"
        set type tunnel
        set interface "port1"
        set ip 172.16.1.1 255.255.255.255
        set remote-ip 172.16.1.254 255.255.255.0
        set allowaccess ping
    next    
end
config router bgp
    set as ${sdwan_asn}
    set ibgp-multipath enable
    set ebgp-multipath enable
    set graceful-restart enable
    set additional-path enable
    set additional-path-select 4
    set graceful-restart-time 1
    set graceful-update-delay 1
    config neighbor
        edit ${bgp_peer}
            set remote-as ${transit_asn}
            set soft-reconfiguration enable
            set ebgp-enforce-multihop enable
        next
    end
    config neighbor-group
        edit VPN-PEERS
            set remote-as ${sdwan_asn}
            set next-hop-self enable
            set soft-reconfiguration enable
            set link-down-failover enable
            set additional-path both
            set adv-additional-path 4
            set route-reflector-client enable
            set keep-alive-timer 5
            set holdtime-timer 15
            set advertisement-interval 1
            set bfd enable
        next
    end
    config neighbor-range
        edit 1
            set prefix 172.16.1.0/24
            set neighbor-group VPN-PEERS
        next
    end    
end
config router static
    edit 1
        set gateway ${lan_gateway}
        set dst ${bgp_peer}/32
        set device port2
    next
end
config firewall policy
    edit 1
        set name "To-Transit"
        set srcintf "HUB"
        set dstintf "port2"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 2
        set name "To-SDWAN"
        set srcintf "port2"
        set dstintf "HUB"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next    
end