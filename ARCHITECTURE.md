## Azure 3-Tier Architecture (Schematic)

```mermaid
flowchart LR
  %% Core flow
  TM[Traffic Manager] --> WLB[Web Load Balancer (Public)]
  WLB --> VMSSW[Web VMSS (Ubuntu + NGINX)]
  VMSSW --> BILB[Business Load Balancer (Internal)]
  BILB --> VMSSB[Business VMSS (Ubuntu)]
  VMSSB --> DILB[Database Load Balancer (Internal)]
  DILB --> SQL1[SQL VM 1 (Win 2022 + SQL 2019)]
  DILB --> SQL2[SQL VM 2 (Win 2022 + SQL 2019)]

  %% Management and AD
  J[Jumpbox (Linux)] -. mgmt .- VMSSW
  J -. mgmt .- VMSSB
  J -. mgmt .- SQL1
  J -. mgmt .- SQL2
  AD[AD DS (Windows Server 2022)] -. DNS .- SQL1
  AD -. DNS .- SQL2
  AD -. mgmt .- J

  %% Subnet notes (labels only)
  classDef note fill:#f8f8f8,stroke:#bbb,stroke-dasharray: 3 3;
  WEB[(Subnet: web)]:::note
  BIZ[(Subnet: business)]:::note
  DB[(Subnet: db)]:::note
  MGMT[(Subnet: management)]:::note

  WEB --- WLB
  BIZ --- BILB
  DB  --- DILB
  MGMT --- J
  MGMT --- AD
```

Notes:
- NSGs: Web (80/443), Management (22/3389), Biz (intra-VNet), DB (1433 from Biz only).
- SQL VMs join the AD domain and sit behind the DB internal load balancer.
- Traffic flows: TM -> Web LB -> Web VMSS -> Biz LB -> Biz VMSS -> DB LB -> SQL VMs.

