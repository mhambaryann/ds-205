drop table if exists employee_details;

drop view if exists combined_room_reservation;
drop table if exists overnight_room_reservation;
drop table if exists meeting_room_reservation;

drop table if exists overnight_room;
drop table if exists meeting_room;
drop table if exists hotel;

drop table if exists food_order;
drop table if exists payment;
drop table if exists feedback;
drop table if exists reservation;

drop table if exists user_authentication;
drop table if exists "user";

create table "user" (
    user_id serial primary key,
    first_name varchar(50) not null,
    middle_name varchar(50),
    last_name varchar(50) not null,
    email varchar(100) unique not null,
    phone_number varchar(20) unique,
    created_at timestamp default NOW()
);

create table user_authentication (
    user_id int primary key references "user"(user_id),
    password_hash text not null,
    password_last_updated timestamp not null,
    totp_secret text,
    security_question text,
    security_question_hash text
);

drop type if exists address;

create type address as (
    street text,
    city varchar(255),
    country varchar(255)
);


create table hotel ( -- same as branch I guess
    hotel_id serial primary key,
    name varchar(100) not null unique,
    hotel_address address,
    branch_manager_id int references "user"(user_id)
);

drop type if exists employee_role;
create type employee_role as enum('branch_manager', 'cleaner', 'support_agent', 'front_desk_agent', 'lobby_attendant', 'security_guard');

create table employee_details (
    user_id int primary key references "user"(user_id),
    role employee_role not null,
    contract_start date not null,
    supervisor_id int references "user"(user_id),
    salary decimal(10, 2) not null,
    salary_transaction_account text,
    hotel_id int references hotel(hotel_id)
);

drop type if exists overnight_room_type;
create type overnight_room_type as enum('single', 'double', 'twin', 'suite', 'studio', 'quad', 'villa', 'penthouse');

create table overnight_room (
    room_id serial primary key,
    hotel_id int references hotel(hotel_id),
    room_number varchar(10) not null,
    price_per_night decimal(10,2) default 50 check (price_per_night >= 0),
    capacity int default 2,
    room_type overnight_room_type,
    unique (hotel_id, room_number)
);


drop type if exists meeting_room_type;
create type meeting_room_type as enum('u-shaped', 'circular', 'classroom', 'conference', 'theater', 'cluster');

drop type if exists meeting_room_equipment;
create type meeting_room_equipment as enum('screen', 'projector', 'video-conferencing', 'whiteboard');

create table meeting_room (
    room_id serial primary key,
    hotel_id int references hotel(hotel_id),
    room_number varchar(10) not null,
    hourly_rate decimal(10, 2) default 50 check (hourly_rate >= 0),
    capacity int default 10,
    room_type meeting_room_type,
    room_equipment meeting_room_equipment
);

drop type if exists reservation_status;
create type reservation_status as enum('reserved', 'canceled', 'in process', 'terminated', 'completed');

create table reservation (
    reservation_id serial primary key,
    user_id int references "user"(user_id),
    check_in_date timestamp not null,
    check_out_date timestamp not null,
    total_cost decimal(10, 2),
    guest_count int,
    created_at timestamp default NOW(),
    status reservation_status default 'reserved'
);


create table overnight_room_reservation (
    reservation_id int references reservation(reservation_id),
    room_id int references overnight_room(room_id)
);

create table meeting_room_reservation (
    reservation_id int references reservation(reservation_id),
    room_id int references meeting_room(room_id)
);

-- to easily see which rooms this reservation reserves
create view combined_room_reservation as
    select reservation_id, room_id, 'overnight' as room_category
    from overnight_room_reservation
union all
    select reservation_id, room_id, 'meeting' as room_category
    from meeting_room_reservation;


create table feedback (
    feedback_id serial primary key,
    reservation_id int references reservation(reservation_id),
    feedback_response text,
    rating int not null check (rating between 1 and 5),
    created_at timestamp default NOW()
);

drop type if exists payment_method_type;
create type payment_method_type as enum('visa', 'master card', 'arca', 'cash', 'check'); -- we can add telcell, idram, etc.

create table payment (
    payment_id serial primary key,
    reservation_id int references reservation(reservation_id),
    transaction_id varchar(255), -- Let's say it is handled by a 3rd party service, like Stripe
    payment_method payment_method_type,
    amount decimal(10, 2),
    created_at timestamp default NOW()
);

create table food_order (
    order_id serial primary key,
    reservation_id int references reservation(reservation_id),
    order_details text,
    amount decimal(10,2),
    created_at timestamp
);
