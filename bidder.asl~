// Agent bidder in project Auction.mas2j

/* Initial beliefs and rules */

init(Budget) :- Budget = 130.

price(InitialPrice, Offer) :- .random(R) & Offer = (20*R)+InitialPrice.

too_offer(B) :- init(B) & try_to_offer(Offer) & Offer > B.


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
	+try_to_offer(Offer);
	!proposeORrefuse(A, CNPId, Auction, Offer).

	   
+informMaxValue(CNPId, Auction, Max_value, BiddersNumber)[source(A)]
	: provider(A,"auctioneer") & init(Budget) & price(Max_value, Offer) & BiddersNumber > 1
	<-
	+try_to_offer(Offer);
	!proposeORrefuse(A, CNPId, Auction, Offer).
	
	
+!proposeORrefuse(A, CNPId, Auction, Offer) // propose if Offer < Budget
	: init(Budget) & try_to_offer(Offer) & not too_offer(Budget)
	<- 
	+proposal(CNPId, Auction, Offer); // mental annotation
	
	.print("NEW PROPOSE: offer ", Offer, " < ", Budget, "\n");
	
	.send(A, tell, propose(CNPId, Offer)).

	
+!proposeORrefuse(A, CNPId, Auction, Offer) // refuse if Offer > Budget
	: init(Budget) & try_to_offer(Offer) & too_offer(Budget)
	<- 
	+refuse(CNPId, Auction, Offer); // mental annotation
	
	.print("TRY TO PROPOSE: offer ", Offer, " < ", Budget);
	.print("BUT REFUSE BECAUSE 'BUDGET NOT SUFFICIENT': ", Offer, " > ", Budget, "\n");
	
	.df_deregister("bidders");
	
	.send(A,tell,refuse(CNPId)).

	
+accept_proposal(CNPId)[source(A)]
   : provider(A,"auctioneer") & proposal(CNPId, Auction, Offer)
   <- 
   +accept(CNPId, Auction, Offer); // mental annotation
   
   .print("-------------------------------------");
   .print("PAYMENT: ", Offer, "$ for ", Auction, " - CNPId ", CNPId);
   .print("-------------------------------------\n");
   
   .send(A, tell, informPayment(CNPId, Auction, Offer)).
