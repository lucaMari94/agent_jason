// Agent bidder in project Auction.mas2j

// random(Budget) :- .random(R) & Budget = (100*R)+100.

init(Budget) :- Budget = 130.

price(InitialPrice, Offer) :- .random(R) & Offer = (20*R)+InitialPrice.

too_offer(B) :- init(B) & proposeORrefuse(A, CNPId, Auction, O) & O > B.


/* Initial beliefs and rules */


/* Initial goals */

!register.


/* Plans */


// register in DF
+!register 
	: true
	<-
	.df_register("bidders");          
	.df_subscribe("auctioneer").
	
	
+cfp(CNPId, Auction, InitialPrice)[source(A)]
	: provider(A,"auctioneer") & price(InitialPrice, Offer)
	<-
	+proposeORrefuse(A, CNPId, Auction, Offer).

	   
+informMaxValue(CNPId, Auction, Value, BiddersNumber)[source(A)]
	: provider(A,"auctioneer") & init(Budget) & price(Value, Offer) & BiddersNumber > 1
	<-
	+proposeORrefuse(A, CNPId, Auction, Offer).
	
	
+proposeORrefuse(A, CNPId, Auction, Offer) // propose if Offer < Budget
	: init(Budget) & proposeORrefuse(A, CNPId, Auction, Offer) & not too_offer(Budget)
	<- 
	+proposal(CNPId, Auction, Offer);
	
	.print("NEW PROPOSE: offer ", Offer, " < ", Budget, "\n");
	
	.send(A, tell, propose(CNPId, Offer)).

	
+proposeORrefuse(A, CNPId, Auction, Offer) // refuse if Offer > Budget
	: init(Budget) & proposeORrefuse(A, CNPId, Auction, Offer) &  too_offer(Budget)
	<- 
	.print("TRY TO PROPOSE: offer ", Offer, " < ", Budget);
	.print("BUT REFUSE BECAUSE 'BUDGET NOT SUFFICIENT': ", Offer, " > ", Budget, "\n");
	
	.df_deregister("bidders");
	
	.send(A,tell,refuse(CNPId)).

	
+accept_proposal(CNPId)[source(A)]
   : provider(A,"auctioneer") & proposal(CNPId, Auction, Offer)
   <- 
   .print("-------------------------------------");
   .print("PAYMENT: ", Offer, "$ for ", Auction, " - CNPId ", CNPId);
   .print("-------------------------------------\n");
   
   .send(A, tell, informPayment(CNPId, Auction, Offer)).