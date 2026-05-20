---
title: "I Vibe Coded a Full-Stack Web App in One Session — Here's What Happened"
subtitle: "From a year-and-a-half of ‘I should really try this' to a live, multi-user web app — built in one session with Claude, Supabase, Next.js, and Vercel"
slug: "i-vibe-coded-a-full-stack-web-app-in-one-session"
date: 2026-03-07
publishedAt: 2026-03-07
author: Saikrishna Poluri
canonical_url: "https://skpoluri.substack.com/p/i-vibe-coded-a-full-stack-web-app"
canonicalUrl: "https://skpoluri.substack.com/p/i-vibe-coded-a-full-stack-web-app"
cover_image: "https://miro.medium.com/v2/resize:fit:1200/1*VwKCNXHwENNGOQZ-iL5hMA.png"
coverImageUrl: "https://miro.medium.com/v2/resize:fit:1200/1*VwKCNXHwENNGOQZ-iL5hMA.png"
tags:
  - software-engineering
  - artificial-intelligence
  - data-engineering
  - web-development
  - programming
  - supabase
  - nextjs
  - vercel
  - vibe-coding
description: "A Senior Data Engineer rebuilds an enterprise Power Apps application in a single session using Claude AI, Supabase, Next.js, and Vercel. Here's how it went."
layout: post
---

Let me get this out of the way: I've spent 9+ years in the data engineering world. Azure Data Factory, Databricks, Synapse, Power BI — that's my comfort zone. I hold multiple Azure certifications (DP-700, DP-600, DP-203) and I've built data pipelines that move millions of records across enterprise systems.

But a full-stack web application? With authentication, role-based access, image uploads, and a live deployment? That was never on my resume.

Until last week.

I sat down, opened Claude AI, and said: *"We need to integrate Supabase and Vercel — make it as a fully functional multi-user app."*

A few hours later, I had a production-ready web application live on the internet. No boilerplate tutorials. No Stack Overflow rabbit holes. No weekend-long debugging sessions.

Just a conversation with an AI and a willingness to ship.

## The Backstory: An Idea That Sat for a Year and a Half

About a year and a half ago, I was leading a migration project — moving legacy Oracle APEX applications to Microsoft Power Platform. I built the Power Apps version of the Furniture Standards Database using Model-Driven Apps on Dataverse, with Copilot assisting the development. It worked. It shipped. It's in production.

But the moment I finished that build, a thought planted itself in my head and never left: *"What if I could build this entire thing — from database to deployment — using just AI tools and open-source tech?"*

Not as a replacement. As an experiment. To see how far AI-assisted development had come.

That idea sat in the back of my mind for almost a year and a half.

Here's the thing that kept bugging me: **Power Apps is locked inside the Microsoft ecosystem.** You need licenses. You need an admin to configure environments. You need GCC compliance checks. It's the right tool for enterprise — but it's slow to iterate and impossible to share with the outside world.

I kept thinking: *What if I could build the same app using open-source tools? Something I could deploy in minutes, share with a URL, and iterate on instantly?*

Then I finally stopped overthinking and just built it.

## The Stack

Here's what I used — and honestly, if you'd told me a year ago that this stack could replace an enterprise app, I would've laughed.

### Claude AI (Vibe Coding Engine)

This is where the magic happened. I didn't write code from scratch. I described what I wanted in plain English, and Claude generated the entire codebase — database schemas, React components, authentication logic, API integrations, deployment configs. Everything.

The term "vibe coding" is new, but the concept is simple: you describe the *vibe* of what you want, and AI translates it into working software. You're the architect, the AI is the builder.

### Supabase (Database + Auth + Storage)

Think of Supabase as "Firebase, but with PostgreSQL." It gave me:

- A real PostgreSQL database with proper relationships and constraints
- Row Level Security (RLS) — so readers can only view data, admins can edit
- Built-in email authentication with signup/login flows
- File storage for product images with access policies
- All hosted, managed, and free-tier friendly

### Next.js (Frontend Framework)

React-based framework that handles both the UI and server-side logic. The app has a public catalog page, a login system, an admin panel with full CRUD operations, and responsive design that works on mobile. All in one codebase.

### Vercel (Deployment + Hosting)

Connected my GitHub repo, added two environment variables, and clicked deploy. That's it. The app was live on a `.vercel.app` URL in under two minutes. Every time I push code to GitHub, Vercel automatically redeploys. Zero DevOps.

### GitHub (Code Repository)

Version control and the bridge between local development and cloud deployment. Push code, Vercel picks it up, app updates. Simple.

## The Session

Fast forward to February 2026. Almost a year and a half of "I should really try this" finally turned into "let's go." Let me walk you through the session as it unfolded, because I think the process is more interesting than the result.

I told Claude: *"We need to integrate Supabase and Vercel — make it as a fully functional multi-user app."* I specified the features I needed:

- User authentication with Reader and Admin roles
- Furniture catalog with search and filters
- Admin CRUD for all lookup tables (categories, manufacturers, facilities, office locations)
- Image upload for product photos

That's it. No wireframes. No PRD. No technical specifications.

Within minutes, I had:

- **4 SQL migration files** — table definitions, row-level security policies, storage bucket config, and seed data
- **28 application files** — React components, authentication logic, admin panels, catalog pages, middleware, styling
- **A setup guide** — step-by-step instructions for Supabase configuration, local development, and Vercel deployment

## The First Hurdles

I unzipped the project, ran `npm install`, and... got errors. I was running commands in the wrong directory in WSL. Classic. Claude walked me through the fix in 30 seconds.

Then `npm run dev` hung for a minute with a webpack warning. I panicked. Claude said: *"That's normal — Next.js is compiling for the first time. Just wait."*

It was fine.

I opened `localhost:3000` and there it was — a fully functional furniture catalog with a navy and gold theme, a login page, and an admin panel. I signed up, made myself an admin via a SQL command, and started adding furniture records.

## The Image Upload Debugging Session

This was the most educational part. The image upload spinner just kept spinning. Claude and I debugged it together:

- First we checked if the Supabase storage bucket existed (it did)
- Then we realized the Row Level Security policies were blocking uploads
- The `is_admin()` function worked for table queries but not in the storage context
- We replaced it with a simpler `auth.role() = 'authenticated'` check

Fixed. Images started uploading instantly.

**This is what vibe coding actually looks like.** It's not magic. You still hit problems. But instead of spending 2 hours on Stack Overflow, you have a conversation and iterate in real-time.

## Deployment

I pushed the code to GitHub, connected the repo to Vercel, added my Supabase keys as environment variables, and deployed. First deployment failed because Vercel didn't auto-detect Next.js — I had to change the Framework Preset from "Other" to "Next.js" in settings.

Second deploy: live on the internet.

## Iteration: The Real Win

Once it was live, I kept going:

- Added a **card/table toggle** to the catalog view (enterprise users prefer table views)
- Removed org-specific branding to make it reusable
- Made the GitHub repo private

Each change was a conversation: I described what I wanted, got the code, pushed to GitHub, and Vercel auto-deployed. The feedback loop was minutes, not days.

## Power Apps vs. Modern Stack — My Honest Take

Since I've now built the same app on both platforms, here's my honest take:

**Neither is "better."** Power Apps is the right choice when you need enterprise governance, Dataverse integration, and GCC compliance. The modern stack is the right choice when you need speed, flexibility, and the ability to share with the world.

The real power move? **Knowing both.**

## What I Learned

**1. The AI didn't just write code — it architected the system.** Claude didn't give me a pile of files. It designed a proper data model with foreign key relationships, implemented row-level security, set up authentication middleware, created reusable components, and structured the project like a senior developer would. The code was clean, organized, and production-grade.

**2. Debugging with AI is weirdly efficient.** When the image upload broke, I didn't Google the error. I showed Claude a screenshot of my browser, and it diagnosed the issue immediately. The back-and-forth felt like pair programming with a senior engineer who never gets frustrated.

**3. The deployment story is incredible.** Push to GitHub → Vercel auto-deploys → live in 60 seconds. Coming from the enterprise world where deployments involve change requests, approval chains, and maintenance windows, this felt almost illegal.

**4. I built a full-stack app without learning React "properly."** I didn't take a React course. I didn't read the Next.js docs cover to cover. I described what I wanted, understood the code that was generated, made decisions about architecture and UX, and shipped. Is that cheating? I don't think so. It's a new way of building.

**5. The hardest part wasn't the code.** The hardest part was deciding to start. I sat on this idea for almost a year and a half because "I'm a Data Engineer, not a web developer." The tech was ready long before I was.

## What This Means for the Rest of Us

If you're reading this and thinking *"This sounds cool but my org would never allow this"* — you're probably right, and that's okay. Here's what I'd take away:

**Learn the modern stack anyway.** Even if your day job is Power Platform or Azure, understanding Supabase, Vercel, and Next.js makes you a more versatile engineer. It changes how you think about what's possible.

**Use AI as a force multiplier, not a crutch.** I didn't blindly copy-paste code. I made architectural decisions, debugged issues, and understood what was being built. The AI accelerated my execution, but the product vision was mine.

**Ship something.** The gap between "I should build this" and "I built this" is smaller than you think. Especially now. Stop planning. Start building.

**Document and share your journey.** Writing this article forced me to reflect on what I learned. Sharing it publicly holds me accountable to keep building.

## What's Next

This was a proof of concept, but the foundation is solid. Here's what I'm planning:

- Add **Power Automate-style notifications** using Supabase Edge Functions
- Build a **dashboard with charts** using Recharts or Chart.js
- Explore **Supabase Realtime** for live updates when admins add new furniture
- Eventually open-source the template so other teams can fork and customize it

## The TL;DR

I'm a Data Engineer who vibe coded a full-stack web app in one session using Claude AI, GitHub, Supabase, Next.js, and Vercel. The app is live, multi-user, and production-grade.

A year and a half ago, I built this app on Power Apps over several weeks. Today, I rebuilt it on open-source tools in a single session using AI. That's how fast the world is moving.

The tools have changed. The question is: **have you?**

---

*If you're an enterprise professional experimenting with AI-assisted development, I'd love to hear your story. Drop a comment or connect with me on [LinkedIn](https://www.linkedin.com/in/saikrishna-poluri/). And if you sat on a side project for months before finally building it — you know exactly what I'm talking about.*

*Originally published on [Substack](https://skpoluri.substack.com/p/i-vibe-coded-a-full-stack-web-app).*
