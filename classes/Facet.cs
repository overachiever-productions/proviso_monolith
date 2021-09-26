using System.Management.Automation;

namespace Proviso.Models
{
    public class Facet
    {
        public string Name { get; set; }

        public Facet(string name)
        {
            this.Name = name;
        }

        /*
    
            Members:    
                .Name
                .AllowHardResetsOrWhatever
    
                .SourceFilePath (for debugging? may NOT need/want). 
    
                .Assertions (List<Assertion>)
                .AddAssertion()
                .RemoveAssertion()??? 
                .GetAssertions() ??? 
    
                .Rebase()
                .Associated Helper Methods. 
    
                .Definitions (List<Definition>) 
                    where, each definition will have: 
                        .Name/Description
                        .Expect 
                        .Test 
                        .Outcome  (as in what was the outcome of the test? did we find/get what we expected, or not? )
                        .Configure 
    
                . Helper methods for definitions - like ... 
                        .Add(Facet/FacetName, DefinitionName, DefinitionObject)
                        .GetDefs()
                        .UpdateDefTestOutcome()? 
                        .etc.
                    
    
        */
    }
}