import re
import os
import azure.functions as func
import sendgrid
from sendgrid.helpers.mail import Mail, Email, To, Content


def main(event: func.EventGridEvent):

    topic_dict = parse_topic(event.topic)
    topic_dict["secretName"] = event.get_json()["ObjectName"]
    format_dict = format_dict_for_email(topic_dict)

    sg = sendgrid.SendGridAPIClient(api_key=os.environ.get("SENDGRID_API_KEY"))
    from_email = Email(os.environ.get("FROM_EMAIL"))
    to_email = [To(s.strip()) for s in os.environ.get("RECIPIENTS").split(";")]
    subject = "Updated Key Vault Secret"
    content = Content(
        "text/html",
        f"<p>The following Key Vault secret has been updated:<br>\n<br>\n{format_dict}<br>\n<br>\nPlease update any applications that rely on this secret as required.</p>",
    )
    mail = Mail(from_email, to_email, subject, content)

    # Get a JSON-ready representation of the Mail object
    mail_json = mail.get()

    # Send an HTTP POST request to /mail/send
    response = sg.client.mail.send.post(request_body=mail_json)


def parse_topic(topic):
    topic_list = list(filter(None, topic.split("/")))
    topic_dict = {
        topic_list[i]: topic_list[i + 1] for i in range(0, len(topic_list), 2)
    }
    return topic_dict


def format_dict_for_email(dict):
    p = []
    for k, v in dict.items():
        p.append("<br><strong>" + format_key_name(k) + ":</strong> " + v)
    return "\n".join(p)


def format_key_name(key):
    key = re.sub("([a-zA-Z])", lambda x: x.groups()[0].upper(), key, 1)
    key = re.sub("([A-Z])", r" \1", key)
    return key
