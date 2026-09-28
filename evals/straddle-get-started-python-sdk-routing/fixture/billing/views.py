from django.http import JsonResponse


def charge_member(request, member_id):
    # Straddle billing not wired up yet.
    return JsonResponse({"member": member_id, "status": "pending"})
