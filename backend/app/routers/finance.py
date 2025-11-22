from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

@router.get("/finance/accounts", response_model=List[schemas.FinanceAccount])
def list_finance_accounts(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_accounts(db, current_user.id)


@router.post("/finance/accounts", response_model=schemas.FinanceAccount, status_code=status.HTTP_201_CREATED)
def create_finance_account(
    payload: schemas.FinanceAccountCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_account(db, current_user.id, payload)


@router.get("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def get_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.put("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def update_finance_account(
    account_id: int,
    payload: schemas.FinanceAccountUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return crud.update_finance_account(db, account, payload)


@router.delete("/finance/accounts/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    crud.delete_finance_account(db, account)


@router.post("/finance/accounts/{account_id}/sync", response_model=schemas.FinanceAccount)
def sync_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    account.last_synced = datetime.utcnow()
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.post("/finance/plaid/link-token")
def create_plaid_link_token(
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """
    Placeholder Plaid link token endpoint to satisfy iOS client.
    Returns a mock link_token and expiration.
    """
    return {
        "link_token": f"mock-link-token-{current_user.id}",
        "expiration": datetime.utcnow().isoformat() + "Z",
    }


@router.post("/finance/plaid/exchange-token")
def exchange_plaid_public_token(
    public_token: str = "",
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """
    Placeholder exchange endpoint; in production this would create an access token.
    """
    if not public_token:
        raise HTTPException(status_code=400, detail="public_token is required")
    return {
        "status": "linked",
        "public_token": public_token,
        "message": "Plaid integration is mocked in this environment.",
    }


@router.get("/finance/transactions", response_model=List[schemas.FinanceTransaction])
def list_finance_transactions(
    account_id: Optional[int] = None,
    limit: int = 50,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.list_finance_transactions(db, current_user.id, account_id=account_id, limit=limit)


@router.post("/finance/transactions", response_model=schemas.FinanceTransaction, status_code=status.HTTP_201_CREATED)
def create_finance_transaction(
    payload: schemas.FinanceTransactionCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_transaction(db, current_user.id, payload)


@router.get("/finance/budgets", response_model=List[schemas.FinanceBudget])
def list_finance_budgets(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_budgets(db, current_user.id)


@router.post("/finance/budgets", response_model=schemas.FinanceBudget, status_code=status.HTTP_201_CREATED)
def create_finance_budget(
    payload: schemas.FinanceBudgetCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_budget(db, current_user.id, payload)


@router.patch("/finance/budgets/{budget_id}", response_model=schemas.FinanceBudget)
def update_finance_budget(
    budget_id: int,
    payload: schemas.FinanceBudgetUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return crud.update_finance_budget(db, budget, payload)


@router.delete("/finance/budgets/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_budget(
    budget_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    crud.delete_finance_budget(db, budget)


@router.get("/finance/summary", response_model=schemas.FinanceSummary)
def finance_summary(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_summary(db, current_user.id)
