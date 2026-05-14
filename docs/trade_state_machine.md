BarterBridge — Trade Lifecycle State Machine

Overview

Every trade in BarterBridge follows a strict lifecycle
controlled by a Finite State Machine.
No trade status can change without passing through
a valid transition defined here.

Why This Matters

This FSM is the single source of truth for trade logic.
Every API endpoint that touches a trade status
will validate against this machine first.
Invalid transitions are rejected before reaching the database.

States Description

DRAFT — Listing created but not yet published
LISTED — Listing is live and visible to all users
PROPOSED — A trade offer has been sent
NEGOTIATING — Counter offers are being exchanged
ACCEPTED — Both parties have agreed to trade
IN_PROGRESS — Trade is actively happening
COMPLETED — Trade successfully finished (terminal)
REJECTED — Receiver declined the offer (terminal)
CANCELLED — Either party withdrew (terminal)
EXPIRED — No activity within allowed time (terminal)
DISPUTED — A problem was reported (terminal for now, V2 adds resolution flow)

Key Rules

Rule 1: A user cannot accept their own trade offer.
Rule 2: A listing in DRAFT state is invisible to other users.
Rule 3: COMPLETED trades cannot be reversed or reopened.
Rule 4: A listing involved in an ACCEPTED or IN_PROGRESS
         trade cannot receive new offers.
Rule 5: EXPIRED trades notify both parties automatically.
Rule 6: DISPUTED trades are escalated to admin review.

Connection to Code

In the backend (Node.js), this FSM will be implemented
as a JavaScript class called TradeStateMachine.
Every trade status update in the API will call
TradeStateMachine.transition() before touching the database.