## Azure 3-Tier Architecture (Schematic)

```mermaid
flowchart LR
  TM[Traffic Manager] --> PIP[Public IP]
  PIP --> WLB[Web Load Balancer]
  subgraph Web[Web Tier - Subnet web]
    WLB --> WBEP[Web BE Pool]
    WBEP --> VMSSW[VMSS: Ubuntu + NGINX]
  end

  subgraph Biz[Business Tier - Subnet business]
    BILB[Internal LB - Biz] --> BIBEP[Biz BE Pool]
    BIBEP --> VMSSB[VMSS: Ubuntu]
  end

  subgraph DB[Database Tier - Subnet db]
    DILB[Internal LB - DB] --> DBEP[DB BE Pool]
    DBEP --> SQL1[Win 2022 + SQL 2019]
    DBEP --> SQL2[Win 2022 + SQL 2019]
  end

  subgraph MGMT[Management Subnet]
    J[Jumpbox (Linux)]
    AD[Windows Server AD DS]
  end

  WLB --- BILB
  BILB --- DILB

  classDef nsg fill:#eef,stroke:#66f,stroke-width:1px;
  classDef lb fill:#efe,stroke:#393,stroke-width:1px;
  classDef vm fill:#fff,stroke:#444,stroke-width:1px;
  class WLB,BILB,DILB lb;
  class VMSSW,VMSSB,SQL1,SQL2,J,AD vm;
```

Notes:
- NSGs: Web (80/443), Management (22/3389), Biz (intra-VNet), DB (1433 from Biz only).
- SQL VMs join the AD domain and sit behind the DB internal load balancer.
- Traffic flows: TM -> Public LB -> Web VMSS -> Biz LB -> Biz VMSS -> DB LB -> SQL.

