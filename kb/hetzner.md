#Why can I not send any mails from my server?
Unfortunately, email spammers and scammers like to use cloud hosting providers. And we at Hetzner naturally want to prevent this. That's why we block ports 25 and 465 by default on all cloud servers. This is a very common practice in the cloud hosting industry because it prevents abuse. We want to build trust with our new customers before we unblock these mail ports. Once you have been with us for a month and paid your first invoice, you can create a limit request to unblock these ports for a valid use case. In your request, you can tell us details about your use case. We make decisions on a case-by-case basis.

As an alternative, you can also use port 587 to send emails via external mail delivery services. Port 587 is not blocked and can be used without sending a limit request.

https://docs.hetzner.com/cloud/servers/faq/#why-can-i-not-send-any-mails-from-my-server