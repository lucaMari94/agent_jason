// Agent auctioneer in project Auction.mas2j

/* Initial beliefs and rules */

stop_with_one_propose(CNPId):- one_proposals_received(CNPId).

stop_with_no_propose(CNPId):- no_proposals_received(CNPId).

all_proposals_received(CNPId)
  :- nb_participants(CNPId,NP) &                 // number of participants
     .count(propose(CNPId,_)[source(_)], NO) &   // number of proposes received
     .count(refuse(CNPId)[source(_)], NR) &      // number of refusals received
     NP = NO + NR.

one_proposals_received(CNPId)
  :- nb_participants(CNPId,NP) & NP = 1.

no_proposals_received(CNPId)
  :- nb_participants(CNPId,NP) & NP = 0.
  
  
/* Initial goals */

!register.

!startAuction(1, auction(jewel), 100).


/* Plans */

// register in DF
+!register 
	: true 
	<- .df_register(auctioneer).

	
// start the CNP // case 0
+!startAuction(CNPId, Auction, InitialPrice)
 	: true
	<- 
	.print("-----------START AUCTION-------------");
	.print(Auction);
	.print("INITIAL PRICE: " , InitialPrice);
	.print("-------------------------------------");
	
	.wait(2000); // wait bidders (2 seconds)
	
	+state(CNPId, cfp);  // annotation: state = call for proposal
	
	// get bidders from DF
	.df_search("bidders", BIDDERS_LIST);
    .print("Sending CFP to ", BIDDERS_LIST);
	.print("-------------------------------------\n\n");
    +nb_participants(CNPId, .length(BIDDERS_LIST)); // annotation: bidder's number
	
	// send CFM message to bidderList with initialPrice
	.send(BIDDERS_LIST, tell, cfp(CNPId, Auction, InitialPrice));
	
	// .wait(all_proposals_received(CNPId), 4000, _); // wait answers (4 seconds)
	
	!contract(CNPId, Auction). // new goal 
	
  
+!contract(CNPId, Auction)
	: (state(CNPId,cfp) | state(CNPId, contract)) 
		& not stop_with_one_propose(CNPId) 
		& not no_proposals_received(CNPId)
	<-
	
	-state(CNPId, cfp);
	+state(CNPId, contract); // phase passages
	
	.wait(all_proposals_received(CNPId), 2000, _); // wait answers (4 seconds)
	
	.print("-------------------------------------");
	
	// find all offers --> save in L
	
	.findall(offer(Offer,A), propose(CNPId, Offer)[source(A)], OFFERS);
    .print("Offers are ", OFFERS);
	
	// if the offers are not empty
	OFFERS \== [];
    .max(OFFERS, offer(Value, Agent));
	
	.print("AUCTIONEER: INFORM MAX OFFER VALUE: ", Value, " of ", Agent);
	.print("-------------------------------------\n");
	
	// send message with max value for new proposal
	-nb_participants(CNPId, .length(BIDDERS_LIST));
	
	.df_search("bidders", BIDDERS_LIST);
	// annotation: bidder's number
    +nb_participants(CNPId, .length(BIDDERS_LIST)); // annotation: bidder's number
	.send(BIDDERS_LIST, tell, informMaxValue(CNPId, Auction, Value, .length(BIDDERS_LIST)));
	
	!contract(CNPId, Auction).

	
+!contract(CNPId, Auction)
	: stop_with_no_propose(CNPId)
	<-
	.df_search("bidders", BIDDERS_LIST);
	.print("-------------------------------------");
	.print("AUCTION ENDED WITHOUT SALE");
	.print("-------------------------------------");
	
	-state(CNPId, contract);
	-+state(CNPId, finished);
	
	true. // finished
	
	
+!contract(CNPId, Auction) // there is ONE PROPOSE --> winnwe --> accept proposal
	: stop_with_one_propose(CNPId)
	<-
	.df_search("bidders", BIDDERS_LIST);
	
	.print("-------------------------------------");
	.print("SEND ACCEPT PROPOSAL TO: ", BIDDERS_LIST);
	.print("-------------------------------------\n");
	
	.send(BIDDERS_LIST,tell,accept_proposal(CNPId));
	-state(CNPId, contract).
	
	
-!contract(CNPId, Auction)
	: state(CNPId, finished)
	<- 
	-state(CNPId, finished);
	-+state(CNPId, end);
	.print("Finished").
	
	
+informPayment(CNPId, Auction, Offer)[source(B)]
	: true
	<-
	.df_search("bidders", BIDDERS_LIST);
	
	.print("-------------------------------------");
	.print("Auction ended");
	.print("Sale occurred");
	.print("ASSET SOLD: ", Auction);
	.print("TO BIDDER:", BIDDERS_LIST);
	.print("FOR: ", Offer, "$");
	.print("-------------------------------------");
	-+state(CNPId, finished).
	

