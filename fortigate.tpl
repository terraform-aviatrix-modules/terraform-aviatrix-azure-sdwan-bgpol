config system global
    set hostname ${hostname}
    set timezone 04
    set admintimeout 60
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
        set srcintf "any"
        set dstintf "port2"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
end
