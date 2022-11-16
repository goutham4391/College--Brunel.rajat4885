$(document).ready(AccordionBoxesHookup);

		function AccordionBoxesHookup()
		{
		 $(".accordionbox").addClass("accordionbox-closed");
		  
			var dropdowns = $('.accordionbox');
			var i = 0;
			
			while(i < dropdowns.length)
			{
				var dropdownWrapper = $(dropdowns[i]);
				var header2 = dropdownWrapper.children('h2');
				var header3 = dropdownWrapper.children('h3');
				
				header2.attr('style', 'cursor: pointer;');
				header3.attr('style', 'cursor: pointer;');
				
				
				// Accordion show / hide event
				header2.bind("click", function (){
					$(this).next(".accordionbox-content").toggle("fast");
					$(this).parent(dropdownWrapper).toggleClass('accordionbox-closed');
				});
              
				header3.bind("click", function (){
					$(this).next(".accordionbox-content").toggle("fast");
					$(this).parent(dropdownWrapper).toggleClass('accordionbox-closed');
				});

				dropdownWrapper.on("keydown", function(e) {
					if (e.which === 13 /*|| e.keyCode == 32*/) {
						e.preventDefault();
						$(this).next(".accordionbox-content").toggle("fast");
						$(this).toggleClass('accordionbox-closed');
						
					}
				});

				i = i + 1;
			}
		}


// RT: Checks for option to hide secondary navigation
if ($('meta[name=HideSecNav]').attr('content') == 1){
  	$( '.secNav' ).eq(0).addClass( 'hideSecNav' );
}