using System;
using System.Management.Automation;
using System.Security.Principal;
using Proviso.Enums;

namespace Proviso
{
    public class DomainCredential
    {
        private PSCredential _credential;
        public ScriptBlock _credentialPromise;

        public bool CredentialsSet { get; private set; }
        public CredentialsType CredentialsType { get; private set; }
        
        private DomainCredential()
        {
            this.CredentialsSet = false;
        }

        public static DomainCredential Instance => new DomainCredential();

        public void SetCredential(PSCredential credential)
        {
            if (credential == null)
                throw new ArgumentNullException("PSCredential Object CANNOT be NULL when adding to DomainCredential object.");

            this.CredentialsSet = true;
            this.CredentialsType = CredentialsType.Cached;
            this._credential = credential;
        }

        public void SetCredentialPromise(ScriptBlock scriptBlock)
        {
            if (scriptBlock == null)
                throw new ArgumentNullException("Credential Promise CANNOT be NULL when adding to DomainCredential object.");

            this.CredentialsSet = true;
            this.CredentialsType = CredentialsType.Promise;
            this._credentialPromise = scriptBlock;
        }

        public PSCredential GetCredential()
        {
            if(this.CredentialsType != CredentialsType.Cached)
                throw new InvalidOperationException("Domain Credentials can NOT be retrieved when they have not been set (or when a Credential Promise has been defined instead).");

            return this._credential;
        }

        public ScriptBlock GetCredentialPromise()
        {
            if (this.CredentialsType != CredentialsType.Promise)
                throw new InvalidOperationException("Domain Credential Promise can NOT be retrieved when it has not been set (or when an actual Credential has been provided).");

            return this._credentialPromise;
        }

        //public bool IsUserInGroup(string user, string group)
        //{
        //    using (WindowsIdentity identity = new WindowsIdentity(user))
        //    {
        //        WindowsPrincipal principal = new WindowsPrincipal(identity);
        //        return principal.IsInRole(group);
        //    }
        //}
    }
}