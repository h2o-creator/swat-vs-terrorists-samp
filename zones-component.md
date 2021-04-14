# Zones component

This component is a pre-coding explanation of how this system is going to be implemented.

(1) A GLOBAL TIMER EVERY 1 HOUR [SKIPPED]

To check for zones which are pending expiration

(2) A TABLE OF ZONES WITH PLAYER INTERACTION [DONE]

Zones that are invested in by a particular team will be stored in this form:

ID - The transaction ID, we're likely to name the table (ZonesTransactions)
TeamID - The team investing in this zone
ZoneID - The area or zone ID that is being invested in
Investment - The amount paid for this zone
Expiry - The expiry timestamp, which will be worked with the global timer
Date - Transaction date for reference and logging

(3) CODE COMPONENTS [DONE]

- Iterator of available area IDs for purchase
- Loading investments of each zone separately (arrays)

(4) IDEAS [DONE]

- A player will be able to invest cash in a zone on behalf of their team
- It will be possible to continue investing at any time
- The zone will be owned by the team that paid more, for a period of time that isn't static and is recommended to be one day
- The next day, transactions drop for the previous day, and the zones are again unowned :)
- Zones will represent assets for the owning team, that means every 5 minutes the team members will receive a cash value as a bonus from assets
    ASSET FORMULA: $250 per zone every 5 minutes = 250nt