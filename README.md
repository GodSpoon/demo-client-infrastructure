# MSP Demo Client Infrastructure

*By Sam King | dev@spoon.rip*

## Hey there! 👋

So you want to see how we can **spoon-feed** infrastructure management to clients? You've come to the right place! This repo is my attempt at showing how modern MSPs can stop stirring up chaos and start serving up some seriously smooth infrastructure workflows.

After years of wrestling with client environments (and trust me, some were messier than my kitchen after making soup), I finally found a recipe that works. This demo shows how you can use **OpenTofu**, **GitHub**, and **Scalr** to create something that's actually... *chef's kiss*... manageable.

## What's Cooking Here?

### For Us MSPs:
- **Stop the Madness**: No more "who changed what when" mysteries
- **Scale Without Breaking**: Manage 50 clients as easily as 5 (well, almost)
- **Sleep Better**: Automated deployments mean fewer 3am emergency calls
- **Look Professional**: Clients love seeing their infrastructure in Git
- **Save Money**: Catch cost issues before they spoon out of control
- **Team Harmony**: No more stepping on each other's toes (or configurations)

### For Our Clients:
- **Transparency**: They can see exactly what we're doing (scary, I know)
- **Reliability**: No more "works on my machine" deployments
- **Security**: We follow the same patterns that work for everyone
- **Growth Ready**: Easy to add more servers when they hit it big
- **Documentation**: Everything is written down (revolutionary!)

## The Secret Sauce

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   GitHub Repo   │───▶│      Scalr      │───▶│   AWS Account   │
│                 │    │                 │    │                 │
│  - All our code │    │  - The brain    │    │ - Where stuff   │
│  - Change history│    │  - Keeps secrets│    │   actually runs │
│  - Reviews       │    │  - Runs plans   │    │ - EC2 boxes     │
│  - Collaboration │    │  - Enforces rules│    │ - Storage       │
│                 │    │  - Tracks costs │    │ - Networking    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## What's Scalr? (And Why Should I Care?)

Okay, so imagine if Terraform had a really smart assistant that handled all the annoying stuff. That's Scalr. It's like having a sous chef who manages all your infrastructure while you focus on the fancy stuff.

Here's what makes it *spoon-derful*:
- **State Management**: No more "oops I corrupted the state file" moments
- **Git Integration**: Push code → magic happens → infrastructure appears
- **Policy Enforcement**: Stops junior devs from spinning up $10k instances
- **Team Access**: Everyone gets exactly the permissions they need
- **Cost Estimation**: Know how much you're spending before you spend it
- **Audit Everything**: Complete paper trail of who touched what

### The Daily Flow:
1. **I write** some infrastructure code
2. **GitHub** stores it and lets my team review it
3. **Scalr** sees the changes and makes a plan
4. **Team** says "looks good" or "are you crazy?"
5. **Scalr** deploys it automatically (if we're feeling brave)
6. **AWS** gets new shiny resources
7. **Client** is happy (hopefully)

## How I Stirred This Together

```
demo-client-infrastructure/
├── README.md                   # You are here! 👈
├── .gitignore                  # Keeps secrets out of Git
├── main.tf                     # The meat and potatoes
├── variables.tf                # All the knobs you can turn
├── outputs.tf                  # The important stuff to remember  
├── terraform.tf                # Where the magic is configured
├── environments/               # Different flavors for different needs
│   ├── dev/
│   │   └── terraform.tfvars   # "Move fast and break things" settings
│   ├── staging/
│   │   └── terraform.tfvars   # "Almost like production" settings
│   └── prod/
│       └── terraform.tfvars   # "Don't mess this up" settings
└── docs/                       # For when I forget how this works
    ├── architecture.md         # Pretty diagrams
    └── runbook.md             # "How to fix things at 2am"
```

## The Ingredients Explained

### `main.tf` - The Main Course
This is where all the real work happens. I've got:
- A VPC (your own little corner of AWS)
- Public and private subnets (for the stuff that needs internet and stuff that doesn't)
- An EC2 server running a simple web page (because everyone loves "Hello World")
- Security groups (the bouncers of the internet)
- An S3 bucket (for all your important files)
- CloudWatch logs (so you know when things go sideways)

**Pro tip**: I try to make everything follow the same naming pattern. Trust me, future you will thank past you when you're managing 20 different clients.

### `variables.tf` - The Spice Rack
These are all the things you might want to change between clients:
- `client_name`: Because "client1" isn't very professional
- `environment`: dev/staging/prod (the holy trinity)
- `aws_region`: Where you want your stuff to live
- `instance_type`: How much horsepower you need
- `ssh_public_key`: Your key to the kingdom (stored safely in Scalr)

### `outputs.tf` - The Serving Suggestion
After everything deploys, these tell you the important stuff:
- Where to find your web server
- How to SSH into it
- What your S3 bucket is called
- Ready-to-copy SSH commands (because who has time to type?)

### `terraform.tf` - The Recipe Instructions
This tells OpenTofu what version to use and how to talk to AWS. Nothing too exciting, but super important. It's like making sure you're using the right type of flour - boring but critical.

### Environment Files - Different Serving Sizes
- **Dev**: Small portions, fast cooking, don't worry if you burn it
- **Staging**: Production-sized but with training wheels
- **Prod**: No mistakes allowed, everything double-checked

## What Actually Gets Built

When you run this, you get a nice little web application setup:

**The Kitchen Equipment:**
- **1 VPC** - Your own private network space
- **2 Subnets** - Public (for web stuff) and private (for database stuff later)
- **1 EC2 Instance** - Running a simple Apache web server
- **1 Elastic IP** - So the address doesn't change when you restart
- **Security Groups** - Only letting in the traffic you want
- **1 S3 Bucket** - For backups and file storage
- **CloudWatch Logs** - So you can see what's happening

**The Bill:**
- **Dev Environment**: About $15-25/month (couple of coffees)
- **Production**: $50-100/month (nice dinner for two)

## Getting Your Hands Dirty

### What You'll Need
- AWS account (and the keys to it)
- GitHub account (free is fine)
- Scalr account (also has a free tier)
- SSH keys (for getting into your servers)
- Coffee (optional but recommended)

### The Quick Version
1. **Clone** this repo
2. **Fix** the SSH key placeholder (use your actual key!)
3. **Set up** Scalr workspace
4. **Add** your AWS credentials to Scalr
5. **Push** some changes
6. **Watch** the magic happen
7. **Try** to look professional when it works

### The "I Want Details" Version
Check out my [detailed setup guide](./docs/scalr-implementation-guide.md) - it's got screenshots and everything!

## Real-World Examples (AKA "Stuff I Actually Do")

### Adding a Database
```bash
# Start a new branch (because main branch is sacred)
git checkout -b feature/add-database

# Add RDS stuff to main.tf
# Update variables for database settings
# Add database outputs

git add .
git commit -m "Add RDS because the client needs to store stuff"
git push origin feature/add-database

# Make a pull request
# Scalr shows what's going to change
# Team reviews (hopefully quickly)
# Merge and watch it deploy
```

### "The Server is On Fire" Emergency
```bash
# When everything is broken and clients are calling
git checkout -b hotfix/security-group-emergency

# Make the minimal fix needed
# Commit with sweaty palms
# Skip the usual review process (just this once!)
# Deploy and pray
# Schedule proper fix for later
```

### Moving from Staging to Production
```bash
# Copy the working staging config
cp environments/staging/terraform.tfvars environments/prod/
# Beef up the instance sizes and storage
# Make sure backup retention is longer
# Triple-check security settings
# Get three people to review it
# Deploy very carefully
```

## Security Stuff (Because Getting Hacked Sucks)

### Infrastructure Security
- **Network Isolation**: Bad guys can't get to your database from the internet
- **Minimal Access**: Only open the ports you actually need
- **Encryption**: Everything stored in S3 is encrypted (just in case)
- **SSH Restrictions**: Only your office IP can SSH in (adjust for remote work)

### Operational Security
- **Secret Management**: AWS keys live in Scalr, not in Git
- **State File Protection**: Scalr keeps your Terraform state safe and backed up
- **Change Tracking**: Every single change is logged and auditable
- **Policy Guards**: Scalr can stop people from doing expensive or dangerous things

## Scaling This to Multiple Clients

The beauty of this setup is that once you get it working for one client, you can **spoon** it out to as many as you want:

### How I Organize Workspaces
```
My MSP Account
├── ACME-Corp/
│   ├── acme-dev
│   ├── acme-staging  
│   └── acme-prod
├── Widget-Co/
│   ├── widget-dev
│   └── widget-prod
└── Internal/
    ├── monitoring
    └── billing-reports
```

### Why This Rocks
- **Copy-Paste Success**: New client setup takes hours, not weeks
- **Consistent Quality**: Everyone gets the same tested, reliable foundation
- **Easier Support**: When you've seen one, you've seen them all
- **Better Margins**: Less time debugging means more time growing

## Keeping the Wheels On

### What Scalr Tracks for You
- **Every Change**: Who changed what and when
- **Cost Trends**: Is this month more expensive than last month?
- **Policy Violations**: Someone tried to launch a 32-core instance in dev
- **Team Activity**: Sarah has been busy this week

### My Monthly Routine
- **Week 1**: Check for any failed runs or policy violations
- **Week 2**: Review costs and see if anyone's getting spoon-happy with resources
- **Week 3**: Update OpenTofu versions and security policies
- **Week 4**: Plan capacity for growing clients

## When Things Go Wrong (And They Will)

### Common "Oops" Moments
- **"State is locked"**: Someone else is running a deployment, wait your turn
- **"Access denied"**: Check your AWS keys or security group rules
- **"Plan failed"**: Usually a typo in the Terraform code
- **"Why is this so expensive?"**: Someone probably picked the wrong instance size

### Who to Blame (Just Kidding!)
- **Me**: Check the [Scalr docs](https://scalr.com/docs) first
- **OpenTofu Team**: Their [docs](https://opentofu.org/docs) are pretty good
- **AWS**: [Their docs](https://docs.aws.amazon.com) are... comprehensive
- **Stack Overflow**: Where all developers go to feel dumb

## Contributing (AKA "Making This Better")

### House Rules
1. **Branch everything**: Main branch is for working code only
2. **Write good commit messages**: "Fixed stuff" doesn't help anyone
3. **Test in dev first**: Don't be the person who breaks production
4. **Get reviews**: Two sets of eyes catch more bugs
5. **Watch deployments**: Make sure your change actually worked

### Coding Standards (So We Don't Hate Each Other)
- Name things consistently: `${client_name}-${environment}-${what_it_is}`
- Tag everything for billing: Finance will thank you
- Comment your security group rules: Future you will thank you
- Document any manual steps: Operations will thank you

## The End Credits

This whole thing started because I got tired of manually configuring the same infrastructure over and over again. Now it's a **spoontaneous** deployment every time someone pushes to Git.

If you have questions, complaints, or just want to chat about infrastructure, hit me up at **dev@spoon.rip**. I promise I don't bite (much).

---

*P.S. - If you found this helpful, star the repo! It makes me feel good about the hours I spent writing Terraform instead of sleeping.*

**Built with ❤️ and way too much coffee by Sam King**

---

*"Give a person a server, and they'll ask for root access. Teach them Infrastructure as Code, and they'll automate themselves out of manual work."* - Ancient DevOps Proverb (probably)
