// Agent auctioneer in project Auction.mas2j

/* Initial beliefs and rules */

stop_one_proposal(CNPId)
  :- nb_participants(CNPId,NP) & NP = 1.

stop_no_proposal(CNPId)
  :- nb_participants(CNPId,NP) & NP = 0.

all_proposals_received(CNPId)
  :- nb_participants(CNPId,NP) &                 // number of participants
     .count(propose(CNPId,_)[source(_)], NO) &   // number of proposes received
     .count(refuse(CNPId)[source(_)], NR) &      // number of refusals received
     NP = NO + NR.
  
  
/* Initial goals */

!register.

!startAuction(1, auction(jewel), 100).


/* Plans */

// register in DF
+!register 
	: true 
	<- .df_register(auctioneer).

	
// start the CNP 
+!startAuction(CNPId, Auction, InitialPrice)
 	: true
	<- 
	.print("-----------START AUCTION-------------");
	.print(Auction);
	.print("INITIAL PRICE: " , InitialPrice);
	.print("-------------------------------------");
	
	.wait(2000); // wait bidders (2 seconds)
	
	+state(CNPId, cfp);  // mental annotation: state = call for proposal
	
	// get bidders from DF
	.df_search("bidders", BIDDERS_LIST);
    .print("Sending CFP to ", BIDDERS_LIST);
	.print("-------------------------------------\n\n");
    
	+nb_participants(CNPId, .length(BIDDERS_LIST)); // mental annotation: bidder's number
	
	// send CFM message to bidderList with initialPrice
	.send(BIDDERS_LIST, tell, cfp(CNPId, Auction, InitialPrice));
		
	!contract(CNPId, Auction). // new goal 

	
+!contract(CNPId, Auction)
	: (state(CNPId,cfp) | state(CNPId,contract))
		& not stop_one_proposal(CNPId) 
		& not stop_no_proposal(CNPId) 
	<-
	-state(CNPId, cfp);
	
	+state(CNPId, contract); // mental annotation, phase passages
	
	.wait(all_proposals_received(CNPId), 2000, _);
	
	.print("-------------------------------------");
	.findall(offer(Offer,A), propose(CNPId, Offer)[source(A)], Offers_list);
	.print("Offers are ", Offers_list);
	
	// if the offers_list is not empty
	Offers_list \== [];
    .max(Offers_list, offer(Max_value, Agent));
	
	.print("AUCTIONEER: MAX OFFER VALUE: ", Max_value, " of ", Agent);
	.print("-------------------------------------\n");
	
	.df_search("bidders", BIDDERS_LIST);
	-nb_participants(CNPId,_); // clear memory
    +nb_participants(CNPId, .length(BIDDERS_LIST)); // annotation: bidder's number
	
	// send message with max value for new proposal
	.send(BIDDERS_LIST, tell, informMaxValue(CNPId, Auction, Max_value, .length(BIDDERS_LIST)));
	
	!contract(CNPId, Auction).
	
	
+!contract(CNPId, Auction)
	: state(CNPId, contract) & stop_one_proposal(CNPId) // context: one proposal
	<- 
	-state(CNPId, contract);
	+state(CNPId, accept_proposal);
	.df_search("bidders", BIDDERS_LIST);
	
	.print("-------------------------------------");
	.print("SEND ACCEPT PROPOSAL TO: ", BIDDERS_LIST);
	.print("-------------------------------------\n");
	
	.send(BIDDERS_LIST,tell,accept_proposal(CNPId)).
	
	
+!contract(CNPId, Auction)
	: state(CNPId, contract) & stop_no_proposal(CNPId) // context: no proposal
	<- 
	.print("Finished");
	true. // finished

	
-!contract(CNPId, Auction)
	: state(CNPId, contract) // fail contract
	<- 
	.print("-------------------------------------");
	.print("AUCTION ENDED WITHOUT SALE");
	.print("-------------------------------------");
	-state(CNPId, contract);
	+state(CNPId, end).
	
	
+informPayment(CNPId, Auction, Offer)[source(B)]
	: state(CNPId, accept_proposal)
	<-
	-state(CNPId, accept_proposal);
	+state(CNPId, end);

	.df_search("bidders", BIDDERS_LIST);
	
	.print("-------------------------------------");
	.print("Auction ended");
	.print("Sale occurred");
	.print("ASSET SOLD: ", Auction);
	.print("TO BIDDER:", BIDDERS_LIST);
	.print("FOR: ", Offer, "$");
	.print("-------------------------------------").
