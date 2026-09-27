from django.http import JsonResponse


def charge_member(request, member_id):
    # Billing provider not chosen yet.
    return JsonResponse({"member": member_id, "status": "pending"})
