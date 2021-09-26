using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
	    public Assertion(string name, ScriptBlock assertionBlock)
	    {

	    }

	    /*
	        Members: 
	            .Name
	            .CodeBlock (I assume I can pass those around strongly typed as System.Automation.xyz.CodeBlocks or whatever. 
	            .ParentFacet        
	            .ExecutionOrder ?


	            .AssertionOutcome 
	                    if it's null, the assertion hasn't been run. 
	                .Execution date/time 
	                .pass/fail 
	                .Exception
	                
	    */

	}
}
